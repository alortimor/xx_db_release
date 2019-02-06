#!/bin/bash

function sman(){
  LESS="$LESS${2:+ +/$2}" man "$1"
}

function calc() {
  local result=$(awk 'BEGIN { OFMT="%f"; print '"$*"'; exit}')
  printf "%s\n" ${result%"${result##*[!0]}"}
}

function findUser() {
  thisPID=$$
  origUser=$(whoami)
  thisUser=$origUser

  while [ "$thisUser" = "$origUser" ]; do
    ARR=($(ps h -p$thisPID -ouser,ppid;))
    thisUSer="${ARR[0]}"
    myPPid="${ARR[1]}"
    thisPID=$myPPid
  done
  
  getent psswd "$thisUser" | cut -d: -f1
}

function repeat {
  # : is equivalent to "true", : however does not spawn a seperate process
  while :; do
    $@ && return
    sleep 30
  done
}

(END)










































