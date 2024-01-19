#!/bin/bash
MYUSER=`whoami`
MYSESSION=`tty | cut -d"/" -f3-`
ALLSESS=`w $MYUSER | grep "^$MYUSER" | grep -v "$MYSESSION" | tr -s "   " | cut -d" " -f2`
OTHERSESSIONS=`echo $ALLSESS | grep pts`
printf "\e[33mCurrent session\e[0m: $MYUSER[$MYSESSION]\n"

while getopts ":u:a::" opt; do
    case $opt in
        u)
            MYUSER="$OPTARG"
            ALLSESS=`w $MYUSER | grep "^$MYUSER" | grep -v "$MYSESSION" | tr -s "   " | cut -d" " -f2`
            ;;
        a)
            OTHERSESSIONS=`w $MYUSER | grep "^$MYUSER" | grep -v "$MYSESSION" | tr -s "   " | cut -d" " -f2`
            ;;
        \?)
            echo "invalid option"
            exit 1
            ;;
        :)
            echo "missing arg"
            exit 1
            ;;
    esac
done

if [[ ! -z $OTHERSESSIONS ]]; then
  printf "\e[33mOther sessions:\e[0m\n"
  w $MYUSER | egrep "LOGIN@|^$MYUSER" | grep -v "$MYSESSION" | column -t
  echo ----------
  read -p "Do you want to force close all your other sessions? [Y]Yes/[N]No: " answer
  answer=`echo $answer | tr A-Z a-z`
  confirm=("y" "yes")

  if [[ "${confirm[@]}" =~ "$answer" ]]; then
  for SESSION in $OTHERSESSIONS
    do
         pkill -9 -t $SESSION
         echo Session $SESSION closed.
    done
  fi
else
        echo "There are no other sessions for the user '$MYUSER'".
fi
