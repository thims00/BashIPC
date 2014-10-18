#!/bin/bash

# NOTES:
# - Special characters that must be escaped exclusively are: * @ \ ]

# Our transliteration tables
source header.sh

# encode() - A function for encoding ASCII to a numeric representation of binary
#
# @arg $1 - A string of ASCII characters.
#
# Return: A string of binary on success, 1 upon failure.
function encode() {
  [ ! "$1" ] && return 1

  str_len=${#1}
  char_str="$1"
  encoded_str=""

  step_cnt=0
  for i in $(seq 0 $((str_len - 1)))
  do
    char=${char_str:step_cnt:1}
    bin=${CHAR_TBL["$char"]}

    let step_cnt++
    let next_step++
  
    encoded_str="${encoded_str}${bin}"
  done

  echo $encoded_str
  return 0
}




# decode() - A function for decoding a numeric binary stream to ASCII characters.
#
# @arg $1 - A binary str
#
# Return: An ASCII string upon success, 1 upon failure.
function decode() {
  [ ! "$1" ] && return 1
  # bit length check 
  
  strm="$1"
  strm_len=${#1}
  byte_cnt=$(echo "$strm_len / 8" | bc)
  decoded_str=""

  #if [ $(( $tr % 2 )) -gt 1 ] ;then
  #  echo "ERROR: decode(): Provided byte stream is not a multiple of 8."
  #fi

  for ((i=0; i<strm_len; i+=8))  
  do
    ind="${strm:i:8}"
    decode_str+="${BIN_TBL[$ind]}"
  done    

  echo "$decode_str"
  return 0
}
