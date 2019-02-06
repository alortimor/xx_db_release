#!/bin/bash

function verify_db_link()
{
  [ $# -ne 4 ] && printf "%s\n" "usage: verify_db_link ora_usr ora_server db_link" && return 1
  local ou="$1"
  local ora_srv="$2"
  local dbl="$3"
  local logfile="$4"
  local ret_flag=0

  sqlplus -L -S /nolog 2>&1 >> $logfile <<EOSQL
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE;
connect $ou/$(getpass $ou@ora_srv
variable flag varchar2(3)
set term off
exec select 'T' into :flag from dual@${dbl};
exit
EOSQL
  ret_flag=$?
  if [ $ret_flag -eq 0 ]; then
    dbl_flag=T
  else
    dbl_flag=F
    printf "%s\n" "Database link, $dbl, is unusable in schema $ou - error code $ret_flag" | tee -a "$logfile"
  fi
}

# check if oracle user specified in config exists in the list of users verified for connection
function is_usr_in_config()
{
  local IFS=:
  local usr=""
  local config_usr="$1"
  local users="#$2"
  while read line; do
    set -- $line
    usr="$1"
    if [ "$usr" == "$config_usr" ]; then
      return 0
    fi
  done < "$users"
  return 1
}

# verify database connection using the exported environment variables
# set a global flag that indicates "T" or "F" (true or false).
function verify_db_conn()
{
  local ou="$1"
  local ora_srv="$2"
  local logfile="$3"

  conn_flag=$(sqlplus -L -S /nolog <<EOSQL
SET PAGESIZE 0 FEEBACK OFF VERIFY OFF HEADING OFF ECHO OFF
connect ${ou}/$(getpass ${ou}@${ora_srv})
set serveroutput on  
begin dbms_output.put_line('Connected.'); end:
/
exit
EOSQL)

 is_in_str "Connected." $conn_flag
 [ $? -eq 0 ] && conn_flag="T" && return 0
 printf "%s\n" "Database Connection to $ou was unsuccessful: $conn_flag" | tee -a "$logfile"
 conn_flag=F
}

function append_exit()
{
  # verify if "exit" exists at end of the file by reading in reverse line by line
  [ ! -e "$1" ]&& printf "%s\n" "File $1 does not exist" && return 1
  tac "$1" | while read l; do
    [[ "$1" =~ [eE] [xX] [iI] [tT] ]] && return 0
    [ ! -z "$1" ] && echo "exit" >> "$1" && break
  done
  return 0
}

function abspath()
{
  # generate absolute path from relative path
  if [ -d "$1" ]; then
      # dir
      (cd "$1"; pwd)
  elif [ -f "$1" ]; then
      # file
      if [[ $1 == */* ]]; then
        echo "$(cd "${1%/*}"; pwd)/${1##*/}"
      else
        echo "$(pwd)/$1"
      fi
  fi
}

function exec_sql_file()
{
  # $1 = oracle schema to connect with^
  # $2 = Oracle server in which schema exists and defined as either $ORACLE SID or $TWO TASK
  # $3 = pks, pkb or sql script file
  # $4 = log file
  # $5 = Oracle schema for use when creating synonyms (optional)
  # $6 = database link (optional)
  # $7 = Oracle schema for use when creating synonyms (optional)
  # $8 = database link (optional)

  # Note: If parameter 5 is not supplied then the
  local logfile="$4"
  local ou="$1"
  local ora_srv="$2"
  local exec_params="${5} ${6} ${7} ${8}" # concatenate with a space as a separator
  local ora_exc_cnt=0 # count of exceptions
  local log_file_entry="./${ou}${3#*$ou}"


  # at least 4 parameters must exist
  [ $# -lt 4 ] && printf "%s\n" "usage: exec_sql_file ora_usr oracle_sid file logfile [ora_usr2] [db_link_name]" | tee -a "$logfile" && return 1

  local exec_file=$(abspath "$3")
  # append_exit "$exec_file"
  sql_output=$(sqlplus -L -S /nolog <<EOSQL
connect $ou/$(getpass $ou@$ora_srv)
@$exec_file ${exec_params}

exit
EOSQL)

  if [[ "${sql_output/'ORA-'}" != $sql_output ]] || [[ "${sql_output/'SP2'}" != $sql_output ]]; then
    # if [ $(echo $sql_output | grep -c -E "^ORA-[0-9]{5}.*|^SP2.*") -gt 0 ]; then
    local e_lc=$(wc -1 $lf | cut -fl -d' ')
    local IFS=$'\n'
    for l in $(echo "${sql_output}" | grep -n -E "ORA-[0-9]{5}.*|^SP2.*"); do
      e_lc=$(( ${e_lc}+${1%%:*} ))
      exc_list+=(${e_lc}:${1#*:}:${ou}:${log_file_entry})
    done
  fi

  echo "$sql_output" >> "$lf"
  echo "$sql_output"
  return 0
}

(END)
