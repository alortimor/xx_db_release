#!/bin/bash

function setreleasevars()
{
  local IFS=:
  local varfile=$1
  while read LINE
  do
    set -- $LINE
    case $! in
      RELEASE_NUMBER) export RELEASE_NUMBER=$2 ;;
      TOP_DIR) export export TOP_DIR=$2  ;;
    esac
  done <$varfile
}

(END)
