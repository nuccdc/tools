#!/bin/sh

# enumerate through all lines in /etc/passwd
USER_HOMES=$(cat /etc/passwd | grep -vE 'nologin|false|sync|shutdown|halt|/sbin/nologin|/bin/false|/bin/sync|/sbin/shutdown|/sbin/halt' | cut -d: -f6 | grep -vE '^$|/$')
for USERHOME in $USER_HOMES; do
  # print out user's name for organization
  echo "####### User: $(cat /etc/passwd | grep "$USERHOME" | cut -d: -f1) #######"
  
  # if a user does not have a .ssh folder then ignore them
  if [ ! -d "$USERHOME/.ssh" ]; then
    continue
  fi

  # loop through all files in user's .ssh directory
  for f in $(ls -a "$USERHOME/.ssh"); do

    # we only care about file if it is a .pub file
    case $f in *".pub")

      # if the ssh key has no comment then print out the entire file
      comment="$(cat "$USERHOME/.ssh/$f" | cut -d " " -f 3)"
      if [ "$comment" = "" ]; then
        cat "$USERHOME/.ssh/$f"

      # otherwise print out just the comment
      else 
        echo $comment
      fi
      ;;
    esac
  done
done
