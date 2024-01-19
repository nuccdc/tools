package main

import (
	"fmt"
	"net"
	"math/big"
  "tunnelbees/schnorr"
  "encoding/gob"
  "golang.org/x/crypto/ssh"
	"io"
	"io/ioutil"
	"os"
	"golang.org/x/crypto/ssh/terminal"
  "time"
  "tunnelbees/crypto"
  "encoding/json"
	"flag"
)


// pre-shared values
var (
  p, g, x *big.Int
)

func main() {
  handshakePort := flag.Int("eport", 312, "specified port for ZK handshake")
  username := flag.String("username", "testuser", "Username for SSH auth")
  password := flag.String("pass", "password", "Password for SSH auth")
  key := flag.String("key", "key.json", "Secret key for ZK handshake")
  host := flag.String("host", "", "Host to be connected to (default \"localhost\") ")

	flag.Usage = func() {
		fmt.Fprintf(flag.CommandLine.Output(), "Usage of tb-client \n")
		fmt.Println("Connects to a tb-server given a port")
		flag.PrintDefaults()
	}

	flag.Parse()

	if flag.Lookup("help") != nil || flag.Lookup("h") != nil {
		flag.Usage()
		return
	}

  data, err := ioutil.ReadFile(fmt.Sprintf("%s", *key))
	if err != nil {
		fmt.Println("Error reading file:", err)
		return
	}

	// Unmarshal the JSON data into a map
	values := make(map[string]string)
	err = json.Unmarshal(data, &values)
	if err != nil {
		fmt.Println("Error unmarshalling JSON:", err)
		return
	}

	p, _ = new(big.Int).SetString(values["p"], 10)
	g, _ = new(big.Int).SetString(values["g"], 10)
	x, _ = new(big.Int).SetString(values["x"], 10)

	conn, err := net.Dial("tcp", fmt.Sprintf("%s:%d", *host, *handshakePort))
	if err != nil {
		panic(err)
	}
	defer conn.Close()

	t, r := schnorr.ProverCommitment(p, g)

	encoder := gob.NewEncoder(conn)

	// Send the commitment to the server
	err = encoder.Encode(&struct {
		T *big.Int
	}{t})

	if err != nil {
		panic(err)
	}

	// Receive challenge from the server
	decoder := gob.NewDecoder(conn)
	var c *big.Int
	err = decoder.Decode(&c)
	if err != nil {
		panic(err)
	}

	// Calculate and send the response
	s := schnorr.ProverResponse(r, c, x, p)
	err = encoder.Encode(s)
	if err != nil {
		panic(err)
	}

	// Receive the verification result from the server
	var verificationResult string
	err = decoder.Decode(&verificationResult)
	if err != nil {
		panic(err)
	}

  if verificationResult == "vs" {
    pq := new(big.Int)
    pq.SetString("4096", 10)
    port := int(crypto.HashWithSalt(t, x).Mod(crypto.HashWithSalt(t, x), pq).Int64())
    if port == 53 || port == *handshakePort { 
      port++
    }

    time.Sleep(2 * time.Second)

    // SSH into the determined port
    // super shit lol should be public key
    sshConfig := &ssh.ClientConfig{
        User: fmt.Sprintf("%s", *username),
        Auth: []ssh.AuthMethod{
            ssh.Password(fmt.Sprintf("%s", *password)), 
        },
        HostKeyCallback: ssh.InsecureIgnoreHostKey(), // WARNING: This is insecure and should be replaced with proper host key verification for production
    }

    sshAddress := fmt.Sprintf("%s:%d", *host, port) // Assuming localhost, replace '127.0.0.1' if needed
    sshClient, err := ssh.Dial("tcp", sshAddress, sshConfig)
    if err != nil {
        panic(err)
    }
    defer sshClient.Close()

		// Step 1: Create an SSH session
		session, err := sshClient.NewSession()
		if err != nil {
			panic(err)
		}
		defer session.Close()

		// Step 2: Setup terminal for interaction
		fd := int(os.Stdin.Fd())
		oldState, err := terminal.MakeRaw(fd)
		if err != nil {
			panic(err)
		}
		defer terminal.Restore(fd, oldState) // restore old terminal settings at the end

		// Redirect IO for communication
		session.Stdout = os.Stdout
		session.Stderr = os.Stderr
		session.Stdin = os.Stdin

		// Create a terminal for this session.
		termWidth, termHeight, err := terminal.GetSize(fd)
		if err != nil {
			termWidth = 80
			termHeight = 24
		}

		// Request pty (pseudo terminal) in xterm with given dimensions

    terminalType := os.Getenv("TERM")
    if terminalType == "" {
        terminalType = "xterm" // Default fallback
    }
		err = session.RequestPty(terminalType, termHeight, termWidth, ssh.TerminalModes{})
		if err != nil {
			panic(err)
		}

		// Step 3: Start a shell
		err = session.Shell()
		if err != nil {
			panic(err)
		}

		// Step 4: Wait until the session completes
		err = session.Wait()
		if err != nil && err != io.EOF {
			panic(err)
		}

  }
}
