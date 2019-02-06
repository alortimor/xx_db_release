#!/bin/bash

# the following function loads rows in a text file, with columns in each row separated by a ":",
# into a "2 dimensional" array. Multi dimensional arrays are not supported in bash 3, so each value
# is separated by a ":"

function load_multi_dim_array()
{
  [ ! -f $1 ] && printf "%s\n" "File, $1, does not exist" && return 1
  local cnt=0
  while IFS=: read line; do
    [ -z $line ] && continue
    ((cnt=cnt+1))
    main_array[cnt]=$line
  done < "$1"
  return 0
}

~
~
~
~
~
~
~
(END)
