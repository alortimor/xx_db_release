#!/bin/bash

# $1 = oracle schema, top level directory and database link config information
# $2 = lower level directories from which scripts are executed as per directory order listed

scriptname=${0##*/}
ora_srv=${ORACLE_SID:-$TWO_TASK}
rel_schema=""
fn=${scriptname%.*} # remove .sh extension
dt=$(date "+%Y%m%d_%H%M%S")
lf=${fn##*/}_${dt}.log # e.g. xxrbsdep_20160425_135010.log
[ ! -z $XXRBSDEP_LOG ] && lf="${XXRBSDEP_LOG}/${lF}"
touch $lf # create empty log file

function usage() {
  printf "%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n" "usage: xxrbsdep.sh [Atrh] -x xmlfile "\
    "-A Orcale script files are applied in file name alphabetical order (default)"\
    "-t Oracle script files are applied in file date/time ascending order"\
    "-r Oracle script files applied in reverse order, combined with -A or -t"\
    "-x xml file - processing metadata required; e.g.; " \
            "<all>" \
            "  <oradata tdID='1' dName='./Database/APPS' owner='APPS' sOwner1='XXRBS_ODI_APPUSER' dbL1='' sOwner2='' dbL2='' />" \
            "  <oradata tdID='2' dName='./Database/XXRBS' owner='XXRBS' dblog='yes' /> "\
            "  <linuxdirs>"\
            "    <dir-tdID='1' dID='1' dName='./Database/APPS/DDL/Create/Tables' customOrder='yes'>"
            "      <sqlfile fID='1' fName='tst_tb13.sql' />"\
            "      <sqlfile fID='2' fName='tst_tb12.sql' />"\
            "    </dir>"\
            "    <dir tdID='2' dID='2' dName='./Database/XXRBS/DML/Insert' customOrder='no'></dir>"\
            "    <dir tdID='1' dID='3' dName='./Database/APPS/DCL/Grant' customOrder='yes'>"\
            "      <sqlfile fID='1' fName='xla_distribution_links.sql' />"\
            "    </dir>"\
            "  </linuxdirs>"\
            "</all>"\
    "-h help"
}

# set optional sort options and obtain file names
reverse=""
prn_fmt="%p\n"
db_logging=1
xmlparser="xml_config.py"
orausers="oradata.dat"
config="config.cfg"
script_config="xxrbsdep_config.dat"
rel_info="release_info.dat"
dos2unix -q $rel_info
file_execute_order="exec_file_order.day"
xmlfile=""

while getopts "hrtAx:2 opt; do
  case $opt in
    r) reverse="-r" ;;
    A) ;; # Do nothing, since A is the default
    t) prn_fmt="%T+\t%p\n" ;;
    x) xmlfile=$OPTARG
       [ ! -f $xmlfile ] && printf "%s\n" "XML file does not exist" | tee -a "$lf" && exit 1
       dos2unix -q $xmlfile
       $xmlparser -x $xmlfile -o oradata > $orausers
       $xmlparser -x $xmlfile -o linuxdirs > $config
       $xmlparser -x $xmlfile -o sqfiles > $file_execute_order
       rel_schema=$($xmlparser -x $xmlfile -o releaseschema)
       [ ! -z $rel_schema ] && db_logging=o ;;
    h) usage && rm -f "$lf" && exit 1 ;; # no need to keep log file when only help is requested
    :) echo "Option -$OPTARG requires an argument." >&2  && exit 1 ;;
    *) echo "Invalid option: $OPTARG" >&2 && exit 1;;
  esac
done

[ ! -f $xmlfile ] && printf "%s\n" "XML file does not exist" | tee -a "$lf" && exit 1
shift $(( $OPTIND - 1 ))

# load all library functions
source db_util.sh
source dblog_lib.sh
source strlib.sh
source array _util.sh

function get_Release_info() (
  local IFS=:
  local varfile=$1
  while read line; do
    set -- $line
    case $1 in
      FULL_SVN_PATH)    full_svn_path=${line#FULL_SVN_PATH:*}
                        rel_component=${full-scn_path##*Tags/}
                        rel_component=${rel_component%%/*) ;;
      REVISION_NUMBER)  rev_number=$2 ;;
   esac
  done < "$varfile"
)

# Declare array variables. The variables are used to associate the top level part of the
# full path to any DDL, DCL or DML sqlplus file. The top level directory then identifies which
# schema to execute the sqlplus script file

# For example, the following file name (with full path)
# ./Database/APPS/DML/Insert/ins_some_table.sql
# which will exist in $2
# will be associated with the following line in the Oracle config file ($1)
# APPS:./Database/APPS/:XXRBS_OFSFGL_APPUSER:

declare -a ora_usr
declare -a ora_dir
declare -a ora_usr2
declare -a db_link
declare -a ora_usr3
declare -a db_link2

function get_ora_data () {
  local orausers="$1"
  # Load all oracle schemas, passwords and directories (from where sql files will be executed within schema)
  load_multi_dim_array "$orausers"
  [ $? -eq 1 ] && printf "%s\n" "Disconnecting due to missing or incorrect Oracle schema configuration" | tee -a "$lf" && exit 1

  local IFS=:
  for ((i=1; i<=${#main_array[@]}; i++)); do
    set -- ${main_array[i]}
    ora_usr[i]="$1"
    ora_dir[i]="$2"
    ora_usr2[i]="$3"
    db_link[i]="$4"
    ora_usr3[i]="$5"
    db_link2[i]="$6"
  done
)

#### 1. Verify all Oracle Database schema connections
function verify_database_connection()
(
  local logfile="$1"
  local ora_sid="$2"
  local rel_schema="$3"
  shift 3
  local all_db_ok="T"

  for o in ${@}; do
    verify_db_conn "${o}" "$ora_sid" "$logfile"
    all_db_ok="${all_db_ok}${conn_flag}"
  done

  # relese schema specified at the command line is optional!
  if [ -n $rel_schema ] && [ $db_logging -eq 0 ]; then
    verify_db_conn "$rel_schema" "$ora_sid" "$logfile"
    all_db_ok="${all_db_ok}${conn_flag}"
  fi

  [[ $all_db_ok =~ [^T] ]] && return 1
  return O
}

###### 2. Verify Database links
function verify_database_link()
(
  local schemas="$1"
  local logfiles="$2"
  local all_dbl_ok

  local IFS=:
  while read line; do
    set -- $line
    if [ ! -z "$4" ]; then # only verify the DB Link if a link is present, if not skip
      verify_db_link "$1" "$ora_srv" "$4" "$logfile"
      all_dbl_ok="${all_dbl_ok}${dbl_flag}"
    fi
    if [ ! -z "$6" ]; then # only verify the DB Link if a link is present, if not skip 
      verify_db_link "$1" "$ora_srv" "$6" "$logfile"
      all_dbl_ok"${all_dbl_ok}${dbl_flag}"
    fi
  done < "$schemas"
  [[ $all_dble_ok =~ [^T] ]] && return 1
  return 0
}

####### 3. Verify directories in which each schemas DDL and DML scripts are located
# function serves a dual purpose, a) verify directories, b) load all arrays for use further on in script
# bash 3, language this script is developed, does not support associative or multi-dimensional arrays

function verify_directory()
{
  local logfiles="$1"
  shift
  local all_dir_ok="T"

  for dr in ${@}; do
    # Ensure directory in the oracle configuration file is a valid directory
    if [ ! -d ${dr} ]; then
      printf "%s\n" "Directory, ${dr}, does not exist. COnfiguration, $config, incorrect!" | tee -a "logfile"
      all_dir_ok="${all_dir_ok}F"
    else
      all_dir_ok="${all_dir_ok}T"
    fi
  done

  [[ $all_dir_ok =~ [^T] ]] && return 1

  return 0
}

# loads an array of files
function load_exec_file_order() {
  local search_str=$1
  local file_to_search=$2
  local custom_list

  custom_list=($grep $search_str $file_to_search))
  if [ ${#custom_list[@]} -gt 0 ]; then
    files=(${custom_list[@]})
  fi
)

#1 set getpass location if it doesn't exist?
getpass_dir=$(grep "GETPASS_DIR" $script_config | cut -f2 -d':')
is_getpass_in_path -eq 0 ] && export PATH=$PATH:$getpass_dir

## 2 Obtain the Release information and rename the log file accordingly. Indicate start of release.
get_Release_info "$rel_info"
[ -z $full_svn_path ] && printf "%s\n" "Release info config is incorrect" | tee -a "$logfile" && exit 1
mv "$lf" "${fn##*/}_${rev_number}_${dt}.log"
lf="${fn##*/}_${rev_number}_${dt}.log"
echo "Release for ${full_svn_path}, revision ${rev_number} - start" >> "$lf"

## 3 Load all Oracle config into seperate arrays
get_ora_data "${orausers}" "${lf}"

## optional step, depending on whether RELEASE schema specified with -s
if [ $db_logging -eq 0 ]; then
  deploy_id=0
  deploy_id=$(log_deploy_create "${rel_schema}" "$ora_srv" "${full_svn_path}" "$rev_number" "${ora_user[@]}")
  valint ${deploy_id}
  if [ $? -eq 1]; then
    echo $deploy_id | tee -a $lf
    printf "%s\n" "Deploy ID could not be allocated"
    exit 1
  fi
  printf "%s\n" "Release for ${full_svn_path} allocated DEPLOY ID : ${deploy_id)" | tee -a "$lf"
fi

## 4 ensure connection to all Oracle schemas are possible
##   including release schema, if applicable
verify_database_connection "$lf" "$ora_srv" "${rel_schema}" "${ora_usr[*]}"
[ $? -eq 1 ] && printf "%s\n" "Incorrect Oracle schema configuration" | tee -a "$lf" && exit 1

## 5. Get schema health report
if [ $db_logging -eq 0 ]; then
  log_schema_health "$rel_schema" "$ora_srv" "$lf" "$deploy_id" "pre" "${ora_usr[@]}"
fi

## 6 Ensure all database links listed in the oracle config file are present and usable!
verify_database_link "$orausers" "$lf"
[ $? -eq 1 ] && printf "%s\n" "Invalid database links" | tee -a "$lf" && exit 1

##7 Ensure directories listed in oracle config file are valid
verify_directory "$lf" "${ora_dir[*]}"
[ $? -eq 1 ] && printf "%s\n" "Invalid directory configuration" | tee -a "$lf" && exit 1

### 8. Execute all oracle scripts found in each directory for the schemas verified in the previous step.
###    Scripts found in each directory follow execution order listed as per config file listing. (config.cfg)
declare -a exc_list # array holds all exceptions identified
file_execute_order="exec_file_order.dat"

# while loop reads through config.cfg, which is populated with the command "$xmlparser -x $xmlfile -o linuxdirs > $config"
while read d; do
  custom_orders=${d#*:}
  d=${d%:*}
  [[ $d == "/" ]] || [[ -z $d ]] && continue
  [ ! -d $d ] && printf "\n%s\n" "Directory, $d, listed in, $config, does not exist" | tee -a "$lf" && continue

  # if exec_file_order.dat exists in the release directory, then use the order listed in the file.
  # exec_file_order.dat is populated with "$xmlparser -x $xmlfile -o sqlfiles > $files_execute_order" in the getopts section, at the start
  # otherwise select all files in the directory in the order as specified in config.cfg
  # if no command line switches were specified and no exec_file_order.dat exists then alphabetic order is assumed
  files=($find ${d} -iregex ".*\(/.sql\|\.prc\|\.pks\|\.pkb\)$" -printf ${prn_fmt} | sort ${reverse}| cut -f2))
  [ ${#files[@]} -eq 0 ] && continue

  if [[ $custom_order == "yes" ]]; then
    load_exec_file_order "$d" "$file_execute_order"
  fi
  printf "\n%s\n" "${#files[@]} files found in ${d}" | tee -a "$lf"

  # Mimick an associative array, using a nested loop to identify schema to apply to. bash 3 does not support associative arrays, hence the workaround!
  for ((i=1; i<=${#ora_dir[@]}; i++)); do
    if [[ $d =~  ${ora_dir[i]} ]]; then
      x=0
      for f in ${files[@]}; do
        (( x++ ))
 
        # log action to database if logging is enabled
        [ $db_logging -eq 0 ] && log_action_create "$rel_schema" "$ora_srv" "$deploy_id" "$f"
        old_lc=$(wc -1 $lf | cut -f1 -d' ')

        #execute script file
        exec_sql_file "${ora_usr[i]}" "$ora_srv" "$f" "$lf" "${ora_usr2[i]} ${db_link[i]} ${ora_usr3[i]} ${db_link2[i]}"
        [ $? -eq 0 ]  && printf "%s\n" "${x} - ${f##*/} execution completed" | tee -a "$lf"

        # log sql output to database if logging is enable
        if [ $db_logging -eq 0 ]; then
          new_lc=$(wc -1 $lf | cut -f1 -d' ') # new total line count
          sql_out=$(tail -n $(( $new_lc-$sold_lc )) ${lf}) # get the additions to the log file
          log_action_update "$rel_schema" "$ora_srv" ${deploy_id} ${f} "${sql_out}" # update db with addition to log
          log_deploy_update "$rel_schema" "$ora_srv" ${deploy_id} "{dql_out}" # update db with addition to log
        fi
      done
    fi
  done
done < "$config"

# 9. Identify Oracle exceptions
if [ ${#exc_list[@]} -gt 0 ]; then
  printf "\n%s|n" "${#exc_list[@]} Exceptions identified during deployment"
  printf "\n%s" "${exc_list[@]}" | tee -a "$lf"
fi

printf "\n%s\n" "Release for ${full_svn_path}, revision ${rev_number} - end" | tee -a "$lf"

## 10. Get schema health report and update db deploy row. Optional step depending
#      whether RELEASE schema specified with the dbLog attribute, e.g. <oradata owner='APPS' dName='./db/APPS', dbLog='yes' />
 if [ $db logging -eg 0]; then
  log_schema_health "$rel_schema" "$ora_srv" "$lf" "$deploy_id" "post" "${ora_usr[@]}"
  log_deploy_update_final "$rel_schema" "$ora_srv" "$deploy_id" "${ora-usr[@]}"
 fi

printf "\n%s\n" "ALL *.sql *.pks and *.pkb files successfully applied"

exit 0


