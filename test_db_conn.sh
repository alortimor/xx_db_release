#!/bin/bash

function is_in_str()
  # usage: is_in_str string_to_search_for string_to_search_in
  case $2 in
    *$1*) true ;;
       *) false ;;
  esac

function verify_db_conn()
{
  local ou="$1"
  local ora_srv="$2"
  local logfile="$3"

  conn_flag=$(sqlplus -L -S /nolog <<EOSQL
  SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
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
  tac "$1" | while read 1; do
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
   elif [ -f "$1"; then
     # file
     if [[ $1 == */* ]]; then
       echo "$(cd "${1%/*}"; pwd)/${1##*/}"
     else
       echo "$(pwd)/$1"
     fi
   fi
}


function log_deploy_update() {
  local ou="$1"
  local ora_srv="$2"
  local dep_id="$3"
  local exc_cnt="$4"
  local post_cnt="$5"
  sqlplus -S /nolog <<ESQL
connect ${ou}/$(getpass ${ou}@${ora_srv})
exec pkg_log.log_action_update(${dep_id}, ${exc_cnt}, ${post_cnt});
exit
ESQL
}

function exec_sql_file()
{
  # $1 = oracle schema to connect with
  # $2 = Oracle server in which schema exists and defined as either $ORACLE_SID or $TWO_TASK
  # $3 = pks, pkb or sql script file
  # $4 = log file
  # $5 = Oracle schema for use when creating synonmys (optional)
  # $6= database link (optional)

  # Note: If parameter 5 is not supplied then the
  local logfile="$4"
  local ou="$1"
  local ora_srv="$2"
  local ora_exc_cnt=0 # count of exceptions
  local oldIFS=$IFS

  # at least 4 parameters must exist
  [ $# -lt 4 ] && printf "%s\n" "usage: exec_sql_file ora_usr oracle_sid file logfile [ora_usr2] [db_link_name]" | tee -a "$logfile" && return 1

  # $5 and $6 are both optional, so if $6 exists, but not $5 then position parameters accordingly
  local sql_exec_params
  if [ -z $5 ] && [ -z $6 ]; then
    sql_exec_params=""
  elif [ -n $5 ] && [ -n $6 ]; then
    sql_exec_params="$5 $6"
  elif [ -z $5 ]; then
    sql_exec_params="$6"
  elif [ -z $6 ]; then
    sql_exec_params="$5"
  fi

  local exec_file=$(abspath "$3")
  append_exit "$exec_file"
  
  sql_output=$(sqlplus -L -S /nolog <<EOSQL
connect £ou/$(getpass $ou@$ora_srv)
@$exec_file ${sql_exec_params}
exit
EOSQL)

  if [[ "${sql_output/'ORA-'}" != $sql_output ]] || [[ "${sql_output/'SP2'}" != $sql_output ]]; then
  # if [ $(echo $sql_output | grep -c -E "^ORA-[0-9]{5}.*|^SP2.*") -gt 0 ]; then

    echo "Exceptions identified for file $3"

    local lc=$(wc -1 $lf | cut -fl -d' ')
    local e_lc=0 # line where excere exception will occur in combined log file
    IFS=$'\n'
    for l in $(echo "${sql_output}" | grep -n -E "^ORA-[0-9]{5}.*|^SP2.*"); do
      e_lc=$(( ${lc}+${1%%:*} ))
      exc_list+=(${e_lc}:${1#*:}:${ou}:${exec_file})
    done
  fi
  echo "$sql_output" >> "$lf"
  return 0
}



declare -a exc_list

[ -z $1 ] && echo "Schema not specified" && exit 1
lf="xxrbsdep_16995_20160302_141058.log"

log_deploy_update "$1" "${TWO_TASK}" "4" "0" "0" "0" "$lf"

echo
echo "Done"


#verify_db_conn "$1" "${TWO_TASK}" "$lf"
#[ $conn_flag == 'F' ] && echo "Database connectionp failed" && exit 1

#exec_file="/ns/apps/ist/deployments/ebs/Branches/CUSTOM/Database/XXRBS_RSBEBS_APPUSER/DDL/Create/Synonyms/synonym_xxrbs_wrapper_prc.sql
#exec_sql_file "$1" "${TWO_TASK}" "$exec_file" "$lf"

#exec_file="/ns/apps/ist/deployments/ebs/Branches/CUSTOM/Database/APPS/DDL/Create/Tables/xxrbs_agg_dly_bal_bs_elig_tmp.sql
#exec_sql_file "$1" "${TWO_TASK}" "$exec_file" "$lf"

#echo "Exception count: ${#exc_list[@]}"
#printf "%s\n" "${exc_list[@]}" >> "$lf"
(END)







































