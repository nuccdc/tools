package main

import (
	"crypto/rand"
	"crypto/rsa"
	"errors"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"strings"
	"time"

	"golang.org/x/crypto/ssh"
)

var (
	errBadPassword = errors.New("permission denied")
)

func main() {
	if len(os.Args) < 2 {
		log.Println("Usage: babygorilla <ssh port. if wrong, it will set default ssh version>")
		return
	}
	realSSHPort := os.Args[1]
	logPath := fmt.Sprintf("/var/log/babygorilla-%s.log", time.Now().Format("2006-01-02-15-04-05-000"))
	logFile, err := os.OpenFile(logPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		log.Println("Failed to open log file:", logPath, err)
	} else {
		log.SetOutput(io.MultiWriter(logFile, os.Stdout))
	}

	defer logFile.Close()

	log.SetFlags(log.LstdFlags | log.Lmicroseconds)

	privateKey, _ := rsa.GenerateKey(rand.Reader, 2048)
	signer, _ := ssh.NewSignerFromSigner(privateKey)

	sshVer := getSSHVersion(realSSHPort)

	log.Println("Starting babygorilla with ssh version:", sshVer)

	serverConfig := &ssh.ServerConfig{
		MaxAuthTries:     6,
		PasswordCallback: passwordCallback,
		ServerVersion:    sshVer,
	}

	serverConfig.AddHostKey(signer)

	for i := 0; i < 4096; i++ {
		go listenToPort(i, serverConfig)
	}

	// wait forever
	wait := make(chan struct{})
	<-wait
}

// gets ssh version from real ssh server. if fails, returns default "SSH-2.0-OpenSSH_9.4p1"
// just calls the ssh server and grabs banner
func getSSHVersion(port string) string {
	// essentially nc localhost $port
	// let's use the net package instead of exec-ing nc
	defaultVer := "SSH-2.0-OpenSSH_9.4p1"
	conn, err := net.Dial("tcp", fmt.Sprintf("localhost:%s", port))
	if err != nil {
		return defaultVer
	}
	defer conn.Close()

	// read the banner
	buf := make([]byte, 1024)
	n, err := conn.Read(buf)
	if err != nil {
		return defaultVer
	}

	// parse the banner
	banner := string(buf[:n])
	if !strings.HasPrefix(banner, "SSH-") {
		return defaultVer
	}

	return strings.TrimSpace(banner)
}

func listenToPort(port int, serverConfig *ssh.ServerConfig) {
	listener, err := net.Listen("tcp", fmt.Sprintf(":%d", port))
	if err != nil {
		log.Println("Failed to listen on port:", port, err)
		return
	}
	defer listener.Close()

	for {
		conn, err := listener.Accept()
		if err != nil {
			continue
		}
		go handleConn(conn, serverConfig)
	}
}

func passwordCallback(conn ssh.ConnMetadata, password []byte) (*ssh.Permissions, error) {
	log.Println(conn.RemoteAddr(), string(conn.ClientVersion()), conn.User(), string(password))
	return nil, errBadPassword
}

func handleConn(conn net.Conn, serverConfig *ssh.ServerConfig) {
	defer conn.Close()
	ssh.NewServerConn(conn, serverConfig)
}
