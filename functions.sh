#!/bin/bash
################################################################################
# Name: Bash Master Slave IPC
# Synopsis: An implementation of master slave processing and forking with IPC
#           communication in Bash.
# File: functions.sh
# Version: 0.1
# Date: 10/12/2015
# Author: Tomm Smith (thims)
# Email: root DOT packet AT gmail DOT com
################################################################################
#
############ ATTENTION ################
# These functions expect and require the following listed variables 
# to exist in the parent environment of the shell.
# plist=() - An indexed array of PIDs of forked/bg'd processes for 
#            the destructor method.
[ ! $plist ] && export plist=()


# Clean up the environment and deal with some of the memory issues.
# @arg $1, $2, $3, ... - A space divided list of PIDs to be killed.
#                        ("Infinite" amount of arguments allowed)
#
# Return: 0
function destruct {
  tmp=("$@")
  
  if [ ${#tmp[*]} -gt 0 ] ;then
    for i in $(seq 0 $((${#tmp[*]} - 1)))
    do
      kill ${tmp[i]} 2> /dev/null
    done
  fi

  return 0
}


# help() - Display the help information and exit with status of $1
# @arg int $1 - The exit status.
function help {
  cat << EOF
$0 -[hed] [argument] - A Simple IPC immplementation in Bash.

  -h, --help        - Show this output and exit.
  -e, --echo <data> - Send the message defined by data to the server.
  -d, --die         - Send the SIGTERM signal to the server.
EOF

  if [ -z "$1" ] && [ $(($1+ -10)) == -10] ;then
    exit 1
  else
    exit $1
  fi
}


# Check for the existence of specified FIFO file, and create it upon failure.
# @arg $1 - The file locations of tested FIFO file.
#
# Return: 0 upon a valid FIFO file existing at said location,
#         1 upon it not existing and creating a FIFO at specified location.
#         2 upon file existing without being a named pipe.
function is_fifo {
  if [ -p "$1" ] ;then
    if [ ! -r "$1" ] || [ ! -w "$1" ] ;then
      echo "ERROR: is_fifo(): The named pipe $1 does not have read/write permissions. Unable to connect."
      return 3
    fi
    return 0

  else
    if [ -e "$1" ] ;then
      echo "ERROR: is_fifo(): $1 is a file that is not a named pipe. Failed to initate FIFO file."
      return 2

    else 
      mkfifo "$1"
      return 1
    fi
  fi    
}


# Listen for a response from the server
# - Blocking.
# @arg $1 - Socket to listen to.
# @arg $2 - 
#
# Return: The data heard.
function listen {
  # Supress the error message displayed by bash due to the kill signal,
  # temporarily reassign stderr to a different fd, then reassign it.
  # SEE: http://stackoverflow.com/questions/5719030/bash-silently-kill-background-function-process/5722850
  exec 3>&2
  exec 2> /dev/null
  response=$(cat "$1")
  exec 2>&3
  exec 3>&-

  echo $response
}


# Delete the specified FIFO file
# @args $1 - Locations of the FIFO to be destroyed.
#
# Return: 0 upon successfully destroying the FIFO.
#         1 upon invalid permission.
#         2 upon file not being a FIFO.
#         3 upon file not existing.
function rm_fifo {
  if [ -e "$1" ] ;then
    if [ ! -p "$1" ] ;then
      echo "ERROR: rm_fifo(): Destination file is not a FIFO file. Not deleting."
      return 2
    elif [ ! -w "$1" ] ;then
      echo "ERROR: rm_fifo(): Destination file does not have write permissions. Deletion failed."
      return 1        
    fi
  else 
    return 3
  fi
}


# Send a command to the server
# - Non-blocking
# @arg $1 - Data to be sent
# @arg $2 - Socket to send it over
#
# Return: PID of fork upon success.
function send {
  echo $1 > "$2" 2> /dev/null &
  plist[${#plist[*]}]=$!

  return 0
}


# Wait for $timeout and terminate listening connection.
# - Non-blocking.
# @arg $1 - Amount of time to sleep before terminating socket.
# @arg $2 - Socket to terminate when timed out. (FIFO location)
#
# This function will internally fork into the background through 
# the logical control list of operation of AND's and subshells.
function timeout {
  sleep $1 && \
  pid=$(pidof cat "$2") && \
  if [ $? -gt 0 ] ;then 
    echo "INTERNAL ERROR: Could not terminate stuck IPC connection." 
  else 
    kill $pid 
    echo "ERROR: Connection to server timed out." 
  fi &

  plist[${#plist[*]}]=$!
  return 0
}
