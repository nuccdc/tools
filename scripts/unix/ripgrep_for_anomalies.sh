#!/bin/sh

# check if we have rg installed, if not, we install it
pushd $(dirname $0) > /dev/null
if ! command -v rg &> /dev/null
then
    # check if we already have it unpacked
    if [ -f ./bins/rg ]; then
      RG_BIN=$(realpath ./bins/rg)
    else
      echo "rg could not be found, installing it via tarball at ./bins/rg.tar.gz"
      tar -xzf ./bins/rg.tar.gz -C ./bins
      RG_BIN=$(realpath ./bins/rg)
    fi
else
    RG_BIN=$(command -v rg)
fi
echo "Using rg at $RG_BIN"

ANOMALOUS_STRINGS='(^|\s)(nc|netcat|curl|wget|ftp|ssh|scp|sftp|telnet|ping|nmap|ncat|openssl|socat)(\s)'
# paths to search
SEARCH_PATHS='/tmp /var/ /etc/init.d/ /etc/rc.d/ /etc/rc.local /etc/cron.* /etc/crontab'
for SEARCH_PATH in $SEARCH_PATHS; do
  $RG_BIN $ANOMALOUS_STRINGS $SEARCH_PATH 2>/dev/null
done
# search user homes
echo "Want to search user homes? press something to continue, or ctrl+c to exit"
read
# user homes from /etc/passwd, we need to ignore nologin and similar. also ignore "/"
USER_HOMES=$(cat /etc/passwd | grep -vE 'nologin|false|sync|shutdown|halt|/sbin/nologin|/bin/false|/bin/sync|/sbin/shutdown|/sbin/halt' | cut -d: -f6 | grep -vE '^$|/$')
for USER_HOME in $USER_HOMES; do
  $RG_BIN $ANOMALOUS_STRINGS $USER_HOME 2>/dev/null
done

popd > /dev/null
