#!/bin/bash

function setvars()
{
local IFS=:
local varfile=$1
export ORAENV_ASK=NO
while read LINE; do
  set -- $LINE
  case $1 in
    ORACLE_HOME) export ORACLE_HOME=$2 ;;
    ORACLE_SID)  export ORACLE_SID=$2 ;;
    ORA_PSWD     export ORA_PSWD=$2 ;;
    ORA_USR)     export ORA_USR=$2 ;;
    ORA_USR1)     export ORA_USR1=$2 ;;
    ORA_PSWD1     export ORA_PSWD1=$2 ;;
  esac
done <$varfile
}

setvars $1
. oraenv 1>/dev/null

(END)
