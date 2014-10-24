#!/bin/bash
################################################################################
# Name: Bash Master Slave IPC 
# Synopsis: An implementation of master slave processing and forking with IPC 
#           communication in Bash.
# File: server.sh
# Version: 0.1
# Date: 10/12/2015
# Author: Tomm Smith (thims)
# Email: root DOT packet AT gmail DOT com
################################################################################
#
########### PROTOCOL DOCS ######################
# Syntax:  <COMMUNICATION CHANNEL>:<COMMAND>:<data>
#
# Possible Channels:
#  - CLIENT
#  - SERVER
#
# COMMANDS:
#   - DIE - Terminate the server.
#   - ECHO - Echo specified data.
#   - ACK - Acknowledge the command.


# General functions
source "./functions.sh"
source "./encoding/encoding.sh"

# Global variables
clie_ipc='./clie.fifo'
serv_ipc='./serv.fifo'




if [ ! -p "$clie_ipc" ] ;then
  mkfifo "$clie_ipc"
fi

if [ ! -p "$serv_ipc" ] ;then
  mkfifo "$serv_ipc"
fi


while [ 1 ] 
do
  ipc_data=$(listen "$serv_ipc")
  
  for data in "$ipc_data"
  do
    IFS=:
    eval data=($(echo "$data"))
    unset IFS
    
    case "${data[0]}" in 
      'CLIENT')
        # ACK packet
        send 'SERVER:ACK:Command acknowledged.' "$clie_ipc"
        
        case "${data[1]}" in
          "DIE")
            echo "CLIENT: DIE: ${data[2]}"
            echo "SERVER: Dieing..."
            exit 0
            ;;

          "ECHO")
            decoded_str=$(decode "${data[2]}")
            echo "CLIENT DATA: ECHO:${decoded_str}"
            ;;

          *)
            send 'SERVER:ERR:Invalid/Malformed data.' "$clie_ipc"
            ;;
        esac

      #*) # Parse error when included?
      #  echo "SERVER ERROR: INVALID COMMAND: $data"
      #  continue
      #  ;;
    esac    
  done
done
