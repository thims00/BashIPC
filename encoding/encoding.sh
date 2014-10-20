#!/bin/bash -x

# NOTES:
# - Special characters that must be escaped exclusively are: * @ \ ]
#   These special conditions are dealt with as grammatical representations in the index, 
#   and the value of both the ASCII table and the BINARY table. 
#   EG. 
#     * - XK_asterisk
#     @ - XK_at
#     \ - XK_backslash
#     ] - XK_bracketright
#
#   See /usr/include/keysymdefs.h for details of identifier names.
#   Also, said grammatical representations are maintained in both 
#   encode() as well as decode() for programmatic symmetry. 
#
# Notes:
#   When passing data, if using single quotes you only have to deal with single quotes carefully.
#   EG. "encode 'She'"'"'s going to go to the show.'"
#   It is suggested to always use single quotes when passing the data for integrity preservation and ensuring 
#   success. 




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

    case "$char" in
      '*')
        bin="${CHAR_TBL['XK_asterisk']}"
        ;;

      '@')
        bin="${CHAR_TBL['XK_at']}"
        ;;

      '\')
        bin="${CHAR_TBL['XK_backslash']}"
        ;;

      ']')
        bin="${CHAR_TBL['XK_bracketright']}"
        ;;

      *)
        bin="${CHAR_TBL[$char]}"
        ;;
    esac

    encoded_str+="$bin"
    
    let step_cnt++
    let next_step++
  done

  echo "$encoded_str"
  return 0
}


# decode() - A function for decoding a numeric binary stream to ASCII characters.
#
# @arg $1 - A binary str
#
# Return: An ASCII string upon success. 
#         - 1 upon failure.
#         - 2 upon invalid character.
#         - 255 upon malformed bit stream.
function decode() {
  [ ! "$1" ] && return 1
  
  echo "$1" | grep "[^01]" &> /dev/null
  if [ $? == 0 ] ;then
    echo "ERROR: decode(): The supplied bit stream included characters and is not a computable stream."
    return 255
  fi

  strm="$1"
  strm_len=${#1}
  decoded_str=""
  
  # bit length check 
  byte_cnt=$(echo "scale=2; $strm_len / 8" | bc)
  whole_num=$(echo "print $byte_cnt % 1" | python)

  if [ $whole_num != 0.0 ] ;then
    echo "ERROR: decode(): Bit stream is not a multiple of 8."
    return 255
  fi

  for ((i=0; i<strm_len; i+=8))  
  do
    ind="${strm:i:8}"
   
    # Character does not exist in the table
    if [ "${BIN_TBL[$ind]}" == '' ] ;then
      echo "ERROR: decode(): Encoded character does not exist in the binary table."
      return 2
    fi

    # Deal with our special characters
    case "${BIN_TBL[$ind]}" in
      'XK_asterisk')
        char='*'
        ;;

      'XK_at')
        char='@'
        ;;

      'XK_backslash')
        char='\'
        ;;

      'XK_bracketright')
        char=']'
        ;;

      *)
        char="${BIN_TBL[$ind]}"
        ;;
    esac

    decode_str+="${char}"
  done    

  echo "$decode_str"
  return 0
}
