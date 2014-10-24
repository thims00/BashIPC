#!/bin/bash
################################################
# Name: Bash Master Slave IPC
# Synopsis: An implementation of master slave processing and forking with IPC
#           communication in Bash.
# File: client.sh
# Version: 0.1
# Date: 10/12/2015
# Author: Tomm Smith (thims)
# Email: root DOT packet AT gmail DOT com
# Notes: In Jesus' name are you healed.
################################################


# General functions
source "functions.sh"
source "encoding/encoding.sh"

# IPC file
clie_ipc='./clie.fifo'
serv_ipc='./serv.fifo'
timeout=30



if [ ! -p "$clie_ipc" ] ;then
  mkfifo "$clie_ipc"
fi

if [ ! -p "$serv_ipc" ] ;then
  mkfifo "$serv_ipc"
fi




if [ $# == 0 ] ;then
  help 1
fi

args=("$@")
for i in $(seq 0 $(($# - 1)))
do
  case "${args[i]}" in
    '-h' | '--help')
      help
      exit 1
      ;;
   
    '-e' | '--echo')
      COMMAND='ECHO'
      DATA="${args[i + 1]}"
      break 1
      ;;

    '-d' | '--die')
      COMMAND='DIE'
      DATA="${args[i + 1]}"
      break 1
      ;;

    *)
      help 1
  esac
done


encoded_data=$(encode "${DATA}")
send "CLIENT:$COMMAND:$encoded_data" "$serv_ipc" 

timeout $timeout "$clie_ipc" 
data=$(listen "$clie_ipc")
if [ ${#data} -gt 0 ] ;then
  IFS=:
  data=($(echo "$data"))
  unset IFS

  if [ ${data[0]} == 'SERVER' ] && [ ${data[1]} == 'ACK' ] ;then
    echo "SERVER DATA: ACK: ACK signal received from server. Handshake successful."

  else
    echo "INTERNAL ERROR: Invalid response from server."
  fi

else 
  echo "Dieing..."
  destruct "${plist[*]}"
  exit 1
fi

destruct "${plist[*]}"
exit 0
