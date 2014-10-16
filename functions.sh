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


# Clean up the environment and deal with some of the memory issues.
# @arg $@ - A space divided list of PIDs to be killed.
#           ("Infinite" amount of arguments allowed)
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
