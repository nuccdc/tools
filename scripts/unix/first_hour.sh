#!/bin/bash

# Package Management
# =======================================================================================
update() {
    echo -e "\n[Running update] Updating packages..."

    case $distro in
        *ubuntu* | *debian* | *mint*)
            apt update > /dev/null 
            apt upgrade -y > /dev/null 
            ;;
        *centos* | *fedora*)
            yum update -y > /dev/null 
            ;;
        *opensuse*)
            zypper refresh > /dev/null
            zypper update -y > /dev/null
            ;;
        *alpine*)
            apk update > /dev/null 
            apk upgrade > /dev/null
            ;;
        *)
            echo "Error updating packages. Moving on..."
            return
            ;;
    esac
    
    echo "[Completed update]"
}

clean_packages() {
    echo -e "\n[Running clean_packages] Cleaning up unnecessary packages..."

    case $distro in
        *ubuntu* | *debian* | *mint*)
            apt install -y deborphan > /dev/null 
            deborphan --guess-data | xargs apt -y remove --purge  > /dev/null 
            deborphan | xargs apt -y remove --purge  > /dev/null 
            ;;
        *centos* | *fedora*)
            yum -y autoremove > /dev/null
            ;;
        *opensuse*)
            zypper packages --orphaned | grep -E '^[ivcud]' | awk '{print $5}' | xargs zypper remove -y --clean-deps > /dev/null
            ;;
        *)
            echo "Error cleaning up packages. Moving on..."
            return
            ;;
    esac

    echo "[Completed clean_packages]"
}

run_debsums() {
    echo -e "\n[Running run_debsums] Running debsums and reinstalling as needed..."

    if [ $distro != *ubuntu* ] || [ $distro != *debian* ] || [ $distro != *mint* ]; then
		apt install -y debsums > /dev/null
   		debsums -g
   		apt install --reinstall $(dpkg -S $(debsums -c) | cut -d : -f 1 | sort -u)
    fi

    echo "[Completed run_debsums]"
}


# Enumeration
# =======================================================================================
enumerate() {
    echo -e "\n[Running enumerate] Enumerating system information. Writing to fh.txt..."
    echo "========== ENUMERATION ==========" >> fh.txt

    # OS information
    hostname=$(hostname)    
    echo "Hostname: $hostname" >> fh.txt

    os_info=$(cat /etc/*-release 2>/dev/null)
    echo "OS Information:" >> fh.txt
    echo "$os_info" >> fh.txt

    # Network information
    interfaces=$(ip a | grep -v "lo" | grep "UP" | awk '{print $2}' | cut -d ":" -f1)
    declare -A ip_addresses
    declare -A mac_addresses
    for interface in $interfaces; do
        ip_addresses["$interface"]=$(ip a show "$interface" | grep "inet" | awk '{print $2}')
        mac_addresses["$interface"]=$(ip a show "$interface" | grep "link/ether" | awk '{print $2}')
    done
    {
        for interface in $interfaces; do
            echo -e "\nInterface: $interface" 
            echo "  IP Address: ${ip_addresses[$interface]}"
            echo "  MAC Address: ${mac_addresses[$interface]}"
        done
    } >> fh.txt

    # Network connections
    echo -e "\nNetwork Connections:" >> fh.txt
    netstat -tulpna >> fh.txt

    # List users
    echo -e "\nUsers:" >> fh.txt
    getent passwd | awk -F: '/\/(bash|sh)$/ {print $1}' >> fh.txt
    getent passwd | awk -F: '/\/(bash|sh)$/ {print $1}' >> /etc/cron.deny

    # List groups
    echo -e "\nGroups:" >> fh.txt
    getent group | awk -F: '{print $1}' | while read -r group; do
        echo "Group: $group" >> fh.txt
        echo "Users: $(getent group "$group" | awk -F: '{print $4}')" >> fh.txt
    done

    # Cron jobs
    echo -e "\nCron Jobs:" >> fh.txt
    directories=("/etc/cron.d" "/etc/cron.daily" "/etc/cron.hourly" "/etc/cron.monthly" "/etc/cron.weekly" "/var/spool/cron" "/etc/anacrontab" "/var/spool/anacron")
    for directory in "${directories[@]}"; do
        echo "Cron Jobs in $directory:" >> fh.txt
        for file in "$directory"/*; do
            if [ -f "$file" ]; then
                echo "File: $file" >> fh.txt
                cat "$file" >> fh.txt
            fi
        done
    done
    echo "[Completed enumerate] Results in fh.txt"
}


# User Accounts
# =======================================================================================
manage_acc() {
    echo -e "\n[Running manage_acc] Changing user passwords and locking accounts (except for yourself and root)..."

    current_user=$(echo $SUDO_USER)
    #  current_user is empty, quit
    if [ -z "$current_user" ]; then
        echo "Error: current user is empty. Exiting. Try running as sudo"
        exit 1
    fi
    for user in $(awk -F':' '$1 != "root" && $1 != "'"$current_user"'" && $7 != "/sbin/nologin" && $7 != "/bin/false" {print $1}' /etc/passwd); do
        new_password=$(openssl rand -base64 12)
        echo "$user:$new_password" | chpasswd
    done

    for user in $(awk -F':' '$1 != "root" && $1 != "'"$current_user"'" && $7 != "/sbin/nologin" && $7 != "/bin/false" {print $1}' /etc/passwd); do
        usermod --shell /sbin/nologin --lock $user
    done
    usermod -s /sbin/nologin root

    echo "[Completed manage_acc]"
}


# SSH
# =======================================================================================
configure_ssh() {
    echo -e "\n[Running configure_ssh] Updating SSH configuration file..."

    if [ -f /etc/ssh/sshd_config ]; then

        sed -i '/^#X11Forwarding/s/^#//' /etc/ssh/sshd_config
        sed -i '/^#MaxAuthTries/s/^#//' /etc/ssh/sshd_config
        sed -i '/^#IgnoreRhosts/s/^#//' /etc/ssh/sshd_config
        sed -i '/^#HostbasedAuthentication/s/^#//' /etc/ssh/sshd_config
        sed -i '/^#PermitRootLogin/s/^#//' /etc/ssh/sshd_config
        sed -i '/^#PermitEmptyPasswords/s/^#//' /etc/ssh/sshd_config

        sed -i 's/^X11Forwarding\s\+.*/X11Forwarding no/' /etc/ssh/sshd_config
        sed -i 's/^MaxAuthTries\s\+.*/MaxAuthTries 3/' /etc/ssh/sshd_config
        sed -i 's/^IgnoreRhosts\s\+.*/IgnoreRhosts yes/' /etc/ssh/sshd_config
        sed -i 's/^HostbasedAuthentication\s\+.*/HostbasedAuthentication no/' /etc/ssh/sshd_config
        sed -i 's/^PermitRootLogin\s\+.*/PermitRootLogin no/' /etc/ssh/sshd_config
        sed -i 's/^PermitEmptyPasswords\s\+.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config

        grep -q '^X11Forwarding\s\+no' /etc/ssh/sshd_config || echo "X11Forwarding no" >> /etc/ssh/sshd_config
        grep -q '^MaxAuthTries\s\+3' /etc/ssh/sshd_config || echo "MaxAuthTries 3" >> /etc/ssh/sshd_config
        grep -q '^IgnoreRhosts\s\+yes' /etc/ssh/sshd_config || echo "IgnoreRhosts yes" >> /etc/ssh/sshd_config
        grep -q '^HostbasedAuthentication\s\+no' /etc/ssh/sshd_config || echo "HostbasedAuthentication no" >> /etc/ssh/sshd_config
        grep -q '^PermitRootLogin\s\+no' /etc/ssh/sshd_config || echo "PermitRootLogin no" >> /etc/ssh/sshd_config
        grep -q '^PermitEmptyPasswords\s\+no' /etc/ssh/sshd_config || echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config
    fi 

    echo "*/10 * * * * root service ssh start" >> /etc/crontab
    echo "*/10 * * * * root systemctl start sshd" >> /etc/crontab

    echo "[Completed configure_ssh]"
}


# Firewall
# =======================================================================================
firewall() {
    echo -e "\n[Running firewall] Installing and allowing ssh in ufw or iptables..."

    case $distro in
        *ubuntu* | *debian* | *mint*)
            apt install -y ufw > /dev/null 
            ufw allow ssh
            ufw default deny incoming
            ufw default allow outgoing
            ufw logging on 
            ufw enable
            ufw reload
            systemctl start ufw
            systemctl enable ufw
            ;;
        *centos* | *fedora*)
            yum install -y epel-release > /dev/null
            yum install -y ufw > /dev/null
            ufw allow ssh
            ufw default deny incoming
            ufw default allow outgoing
            ufw logging on 
            echo "y" | ufw enable
            ufw reload
            systemctl start ufw
            systemctl enable ufw
            ;;
        *opensuse*)
            iptables -P INPUT DROP
            iptables -P FORWARD DROP
            iptables -A INPUT -p tcp --dport 22 -j ACCEPT
            iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT
            iptables -A INPUT -i lo -j ACCEPT
            iptables -A OUTPUT -o lo -j ACCEPT
            systemctl start iptables
            systemctl enable iptables
            iptables -N LOGGING
            iptables -A INPUT -j LOGGING
            iptables -A LOGGING -j DROP
            service iptables save
            service iptables restart
            ;;
        *)
            echo "Error setting up ufw/iptables. Moving on..."
            return
            ;;
    esac

    echo "[Completed firewall]"
}


# Logging
# =======================================================================================
fail2ban() {
    echo -e "\n[Running fail2ban] Installing and starting fail2ban..."
    case $distro in
        *ubuntu* | *debian* | *mint*)
            apt install -y fail2ban > /dev/null 
            ;;
        *centos* | *fedora*)
            yum install -y fail2ban > /dev/null 
            ;;
        *opensuse*)
            zypper install -y fail2ban > /dev/null 
            ;;
        *alpine*)
            apk add fail2ban > /dev/null
            rc-update add fail2ban
            rc-service fail2ban start
            echo '[sshd]
                enabled = true
                port = ssh
                filter = sshd
                logpath = /var/log/messages
                backend = auto
                maxretry = 3
                bantime = 1d
                ignoreip = 127.0.0.1' > /etc/fail2ban/jail.local
            rc-service fail2ban start
            return
            ;;
        *)
            echo "Error installing fail2ban. Moving on..."
            return
            ;;
    esac

    systemctl start fail2ban
    systemctl enable fail2ban > /dev/null

    echo '[sshd]
    enabled = true
    port = ssh
    filter = sshd
    logpath = /var/log/auth.log
    maxretry = 3
    bantime = 1d
    ignoreip = 127.0.0.1' > /etc/fail2ban/jail.local

    systemctl restart fail2ban

    echo "[Completed fail2ban]"
}

auditd() {
    # /etc/audit/auditd.conf
    echo -e "\n[Running auditd] Installing and setting rules for auditd..."

    case $distro in
        *ubuntu* | *debian* | *mint*)
            apt install -y auditd > /dev/null
            ;;
        *centos* | *fedora*)
            yum install -y audit > /dev/null 
            ;;
        *opensuse*)
            zypper install -y audit > /dev/null 
            ;;
        *alpine*)
            apk add audit > /dev/null 
            ;;
        *)
            echo "Error installing auditd. Moving on..."
            return
    esac

    if [[ $distro != *alpine* ]]; then
		systemctl start auditd
		systemctl enable auditd > /dev/null 
    else
		rc-service auditd start
		rc-update add auditd
    fi

    auditctl -e 1 > /dev/null 
    auditctl -w /etc/audit/ -p wa -k auditconfig
    auditctl -w /etc/libaudit.conf -p wa -k auditconfig
    auditctl -w /etc/audisp/ -p wa -k audispconfig
    auditctl -w /etc/sysctl.conf -p wa -k sysctl
    auditctl -w /etc/sysctl.d -p wa -k sysctl
    auditctl -w /etc/cron.allow -p wa -k cron
    auditctl -w /etc/cron.deny -p wa -k cron
    auditctl -w /etc/cron.d/ -p wa -k cron
    auditctl -w /etc/cron.daily/ -p wa -k cron
    auditctl -w /etc/cron.hourly/ -p wa -k cron
    auditctl -w /etc/crontab -p wa -k cron
    auditctl -w /etc/sudoers -p wa -k sudoers
    auditctl -w /etc/sudoers.d/ -p wa -k sudoers
    auditctl -w /usr/sbin/groupadd -p x -k group_add
    auditctl -w /usr/sbin/groupmod -p x -k group_mod
    auditctl -w /usr/sbin/addgroup -p x -k add_group
    auditctl -w /usr/sbin/useradd -p x -k user_add
    auditctl -w /usr/sbin/userdel -p x -k user_del
    auditctl -w /usr/sbin/usermod -p x -k user_mod
    auditctl -w /usr/sbin/adduser -p x -k add_user
    auditctl -w /etc/login.defs -p wa -k login
    auditctl -w /etc/securetty -p wa -k login
    auditctl -w /var/log/faillog -p wa -k login
    auditctl -w /var/log/lastlog -p wa -k login
    auditctl -w /var/log/tallylog -p wa -k login
    auditctl -w /etc/passwd -p wa -k users
    auditctl -w /etc/shadow -p wa -k users
    auditctl -w /etc/sudoers -p wa -k users
    auditctl -w /bin/rmdir -p x -k directory
    auditctl -w /bin/mkdir -p x -k directory
    auditctl -w /usr/bin/passwd -p x -k passwd
    auditctl -w /usr/bin/vim -p x -k text
    auditctl -w /bin/nano -p x -k text
    auditctl -w /usr/bin/pico -p x -k text
    
    echo "[Completed auditd]"
}


# Configs
# =======================================================================================
ips() {
    echo -e "\n[Running ips] Disabling ipv6 and ip forwarding..."

    sysctl -w net.ipv6.conf.all.disable_ipv6=1
    sysctl -w net.ipv6.conf.default.disable_ipv6=1

    echo "[Completed ips]"
}

change_bin() {
    echo -e "\n[Running change_bin] Deleting telnet, nc; changing to curlbk, wgetbk..."

    rm $(which telnet) 2>/dev/null
    rm $(which nc) 2>/dev/null

    mv $(which curl){,bk} 2>/dev/null
    mv $(which wget){,bk} 2>/dev/null

    echo "[Completed change_bin]"
}

modules() {
    echo -e "\n[Running modules] Disable ability to load new modules..."

    sysctl -w kernel.modules_disabled=1 > /dev/null
    echo 'kernel.modules_disabled=1' > /etc/sysctl.conf

    echo "[Completed modules]"
}

rpcbind() {
    echo -e "\n[Running rpcbind] Disabling rpcbind..."

    case $distro in
        *ubuntu* | *debian* | *mint* | *centos* | *fedora* | *opensuse*)
            systemctl stop rpcbind 2>/dev/null
            systemctl stop rpcbind.socket 2>/dev/null
            systemctl stop rpcbind.service 2>/dev/null
            systemctl disable rpcbind 2>/dev/null
            systemctl disable rpcbind.socket 2>/dev/null
            systemctl disable rpcbind.service 2>/dev/null
   		    systemctl mask rpcbind  2>/dev/null
   		    ;;
        *alpine*)
            rc-service rpcbind stop 2>/dev/null
            rc-update del rpcbind 2>/dev/null
            apk del rpcbind 2>/dev/null
   		    ;;
   	    *)
            echo "Error disabling rpcbind. Moving on..."
            return
   		    ;;
    esac
    
    echo "[Completed rpcbind]"
}


# Antivirus 
# =======================================================================================
run_clamav() {
    echo -e "\n[Running clamav] Running clamav scan. Writing to fh.txt..."

    case $distro in
        *ubuntu* | *debian* | *mint*)
   		    apt install -y clamav clamav-daemon > /dev/null
   		    ;;
   	    *centos* | *fedora*)
   		    yum install -y clamav clamav-server > /dev/null
   		    ;;
   	    *opensuse*)
   		    zypper install -y clamav clamav-daemon > /dev/null
   		    ;;
   	    *alpine*)
   		    apk add clamav clamav-daemon > /dev/null
   		    ;;
   	    *)
   		    echo "Error running clamav scan. Moving on..."
            return
   		    ;;
    esac

    if [[ $distro != *alpine* ]]; then
		systemctl start clamav-freshclam
    else
		rc-service clamd start
		rc-update add clamd
    fi

    echo -e "\n========== ClamAV Scan ==========" >> fh.txt
    freshclam > /dev/null
    mkdir /tmp/virus
    clamscan -ri --remove --move=/tmp/virus /home/ /bin/ /sbin/ /usr/bin/ /usr/sbin/ /etc/ /tmp/ /var/tmp/ >> fh.txt 2>/dev/null

    echo "[Completed clamav] Results in fh.txt"
}

run_chkrootkit() {
    echo -e "\n[Running chkrootkit] Checking for rootkits. Writing to fh.txt..."

    case $distro in
        *ubuntu* | *debian* | *mint*)
            apt install -y chkrootkit > /dev/null
   		    ;;
   	    *centos* | *fedora*)
            if ! which wget &> /dev/null; then
   		        wgetbk ftp://ftp.chkrootkit.org/pub/seg/pac/chkrootkit.tar.gz -O chkroot.tar.gz > /dev/null
            else
                wget ftp://ftp.chkrootkit.org/pub/seg/pac/chkrootkit.tar.gz -O chkroot.tar.gz > /dev/null
            fi
            yum install -y tar > /dev/null
            tar -xf chkroot.tar.gz
            mv chkrootkit*/chkrootkit chkrootkit
   		    ;;
        *opensuse*)
            if ! which wget &> /dev/null; then
                wgetbk ftp://ftp.chkrootkit.org/pub/seg/pac/chkrootkit.tar.gz -O chkroot.tar.gz > /dev/null
            else
                wget ftp://ftp.chkrootkit.org/pub/seg/pac/chkrootkit.tar.gz -O chkroot.tar.gz > /dev/null
            fi
            zypper install -y tar > /dev/null
            tar -xf chkroot.tar.gz
            mv chkrootkit*/chkrootkit chkrootkit
            ;;
   	    *)
   		    echo "Error checking for rootkits. Moving on..."
            return
   		    ;;
    esac

    echo -e "\n========== Chkrootkit ==========" >> fh.txt
    chkrootkit | grep -E 'INFECTED|suspicious' >> fh.txt

    echo "[Completed chkrootkit] Results in fh.txt"
}

run_rkhunter() {
    echo -e "\n[Running rkhunter] Checking for rootkits. Writes to /var/log/rkhunter/rkhunter.log..."

    case $distro in
        *ubuntu* | *debian* | *mint*)
            apt install -y rkhunter > /dev/null
            ;;
        *centos* | *fedora*)
            yum install -y rkhunter > /dev/null
            ;;
        *opensuse*)
            zypper install -y rkhunter > /dev/null
            ;;
        *)
            echo "Error running rkhunter. Moving on..."
            return
            ;;
    esac

    rkhunter --update > /dev/null
    rkhunter --propupd > /dev/null
    rkhunter -c --enable all --disable none --sk > /dev/null

    echo "[Completed rkhunter] Results in /var/log/rkhunter/rkhunter.log"
}


# Backups
# =======================================================================================
backup() {
    echo -e "\n[Running backup] Backing up files in /var/backups..."
    
    mkdir -p /var/backups
    cp -r /etc/pam* /var/backups 2>/dev/null
    cp -r /lib/security* /var/backups 2>/dev/null
    cp -r /etc /var/backups 2>/dev/null

    if [ -d "/var/www" ]; then
        cp -r /var/www /var/backups 2>/dev/null
    fi
    cd /var
    chattr -R +i backups 2>/dev/null

    echo "[Completed backup]"
}

# Check if running script as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root. Exiting"
    exit 1
fi

# Determine linux distro and call appropriate functions
if [ -e /etc/os-release ]; then
    . /etc/os-release
    distro=$ID
    echo "Detected: $distro"

    manage_acc
    configure_ssh
    update
    clean_packages
    run_debsums
    ips
    modules
    rpcbind

    # -e enumerate (results in fh.txt)
    # -f firewall (ufw/iptables)
    # -l logging (fail2ban, auditd)
    # -b backups (in /var/backups)
    # -n change_bin (wget, curl)
    # -a antivirus (clamav, chkrootkit, rkhunter)
    while getopts "eflbah" opt; do
        case $opt in
            e)
                enumerate
                ;;
            f)
                firewall
                ;;
            l)
                fail2ban
                auditd
                ;;
            b)
                backup
                ;;
            n)
                change_bin
                ;;
            a)
                run_clamav
                run_chkrootkit
                run_rkhunter
                ;;
            h)
                echo "-e enumerate"
                echo "-f firewall (ufw/iptables)"
                echo "-l logging (fail2ban, auditd)"
                echo "-b backups (in /var/backups)"
                echo "-a antivirus (clamav, chkrootkit, rkhunter)"
                ;;
            \?)
                echo "Invalid option: -$OPTARG"
                ;;
        esac
    done

else
    echo "Unable to determine distro. Exiting"
    exit 1
fi
