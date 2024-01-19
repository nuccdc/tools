#!/bin/bash

# quit if not root
if [ $UID -ne 0 ]; then
  echo "You must be root to run this script."
  exit 2
fi

is_installed() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check for iptables rules
check_iptables() {
    echo "Checking iptables..."
    if iptables -L -n | grep -qE 'Chain [^ ]+ \(policy (ACCEPT|DROP)'
    then
        echo "iptables has active rules."
    else
        echo "iptables does not have active rules."
    fi
}

# Function to check for nftables rules
check_nftables() {
    echo "Checking nftables..."
    if nft list ruleset | grep -qE '\s+type filter hook'
    then
        echo "nftables has active rules."
    else
        echo "nftables does not have active rules."
    fi
}

# Function to check for ufw status
check_ufw() {
    echo "Checking ufw..."
    if ufw status | grep -q 'Status: active'
    then
        echo "ufw is active."
    else
        echo "ufw is inactive or not installed."
    fi
}

# Check for iptables
if is_installed iptables; then
    check_iptables
else
    echo "iptables is not installed."
fi

# Check for nftables
if is_installed nft; then
    check_nftables
else
    echo "nftables is not installed."
fi

# Check for ufw
if is_installed ufw; then
    check_ufw
else
    echo "ufw is not installed."
fi
