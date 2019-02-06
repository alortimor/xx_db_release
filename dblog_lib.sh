#!/bin/bash

function get_invalid_cnt() {
  local invalid_cnt=0
  local ou="$1"
  local ora_srv="$2"
  shift 2
  local schemas
  schemas="$@"

  # dba_objects cannot be referenced within a package if SELECT is granted via a role.
  # Hence the use of an nonymou block
  invalid_cnt=$(sqlplus -l -s ${ou}/$(getpass ${ou}@${ora_srv}) <<EOSQL
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
set serveroutput on
declare
  n pls_integer;
  l_schema_list varchar2(200) := '${schemas}';
begin
  execute immediate 'begin
                       select count(*) into :1
                       from dba_objects
                       where owner in (with t as (select replace(:2, '' '', '','') as schema_list from dual
                                       --
                                       select regexp_substr(t.schema_list, ''[^,]+'',1,rownum
                                       from   t
                                       connect by rownum <= (length(t.schema_list) - length(replace(t.schema_list,'',''))+1)
                                      )
                       and status=''INVALID'';
                    end;' using in out n, in l_schema_list;
  dbms_output.put_line(n);
end;
/
exit
EOSQL)
echo $invalid_cnt
}

function log_action_create() {

  local ou="$1"
  local ora_srv="$2"
  local deploy_id="$3"
  local release_item="$4"
  local ret

  ret=$(sqlplus -s -1 ${ou}/$(getpass ${ou}@${ora_srv}) <<EOSQL
SET PAGESIZE 0 FEEBACK OFF VERIFY OFF HEADING OFF ECHO OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
exec pkg_log.log_action_create(${deploy_id}, '${release_item}');
exit
EOSQL)
}

function log_action_update() {

  local ou="$1"
  local ora_srv="$2"
  local deploy_id="$3"
  local release_items="$4"
  local log="$5"
  local ret
  local clob_cnt
  (( clob_cnt=(${#log}/239)+1))
  local start_pos=0
  local IFS=$'\n'
  local clob_inc

  for ((clob_inc=1; clob_inc<=${clob_cnt}; clob_inc++)); do
    tmp_str="${log:${start_pos}:239}"
    ret=$(sqlplus -l -s ${ou}/(getpass ${ou}@{ora_srv)) <<EOSQL
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
begin pkg_log.log_action_update(${deploy_id}, '${release_item}','${tmp_str}'); end;
/
exit
EOSQL)
  ((start_pos=(${clob_inc}*239)+1))
  done
)

function log_deploy_create() {
  local ou="$1"
  local ora_srv="$2"
  local svn_url="$3"
  local rev_num="$4"
  shift 4
  chemas="$@"

  local cnt=0
  cnt=$(get_invalid_cnt $ou $ora_srv $schemas)

  sqlplus -s -l ${ou}/$(getpass ${ou}@${ora_srv}) <<EOSQL
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
variable dep_id number
begin pkg_log.log_deploy_create('${ora_srv}', '${svn_url}', ${rev_num}, '${lf}', '${schemas}', ${cnt}, '$USER', :dep_id); end;
/
print :dep_id
exit
EOSQL
}

function log_deploy_update() {
  local ou="$1"
  local ora_srv="$2"
  local deploy_id="$3"
  local log="$4"
  local clob_cnt
  local ret=0
  (( clob_cnt=(${#log}/239+1))
  local start_pos=0
  local IFS=$'\n'
  local clob_inc

  for ((clob_inc=1; clob_inc<=${clob_cnt}; clob_inc++)); do
    tmp_str="${log:${start_pos}:239}"
    ret=$(sqlplus -l -s ${ou}/$(getpass ${ou_srv}) <<EOSQL
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
begin pkg_log.log_deploy_update(${deploy_id}, '${tmp_str}'); end;
/
exit
EOSQL)
  ((start_pos=(${clob_inc}*239)+1))
  done
}

function log_deploy_update_final() {
  local ou="$1"
  local ora_srv="$2"
  local dep_id="$3"
  shift 3
  local schemas
  schemas="$@"

  local cnt=0
  cnt=$(get_invalid_cnt $ou $ora_srv $schemas)

  sqlplus -s /nolog <<ESQL
connect ${ou}/$(getpass ${ou}@${ora_srv})
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
begin pkg_log.log_deploy_update_final(${deploy_id}, ${cnt}); end;
/
exit
ESQL
}


function log_schema_health() {
  local ou="$1"
  local ora_srv="$2"
  local lf="$3"
  local dep_id="$4"
  local pre_post_flag="$5"
  shift 5
  local schemas
  schemas="$@"
  local delimited_str
  delimited_str=$(arr_to_delimited_str ${schemas})

  sqlplus -s /nolog <<ESQL
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
connect $ou/$(getpass $ou@${ora_srv})
set serveroutput on
declare
  l_sql           varchar2(5000);
  l_schema_list   varchar2(200)  := '${schemas}';
  l_pre_post_flag varchar2(4)    := '${pre_post_flag}';
  l_dep_id        number         := ${dep_id};
  l_cnt           pls_integer    := 0;
  begin
    l_sql ;= 'insert into release_health (deploy_id
                                         ,health_date
                                         ,pre_post_flag
                                         ,schema_owner
                                         ,object_name
                                         ,object_type
                                         ,object_created
                                         ,last_ddl_time
                    select               :1
                                         ,current_timestamp
                                         ,:2
                                         ,do.owner
                                         ,do.object_name
                                         ,do.object_type
                                         ,do.created
                                         ,do.last_ddl_time
                     from dba_objects do
                     where do.owner in (''' || replace(l_schema_list, ' ', ''',''') || ''')
                     and   do.status = ''INVALID''';
    execute immediate l_sql using in l_dep_id, in l_pre_post_flag;
    l_cnt := sql%rowcount;
    commit;
    if (1_cnt > 0) then
      dms_output.put_line('Table RELEASE_HEALTH updated with invalid objects');
    end if;
end;
/

exit
ESQL

  # ORACLE_SCHEMA_LIST is a placeholder
  # sed -i 's@\ORACLE_SCHEMA_LIST@'"${delimited_str"'@' $ora_rep_sql_file
  local hr # variable to hold health report
  local IFS=" "
  hr=$(sqlplus -l -s $ou/$(getpass $ou@${ora_srv}) <<EOSQL
SET FEEDBACK OFF VERIFY OFF ECHO OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE;
set linesize 1000
set pagesize 10000
set heading off
select 'ORACLE SCHEMA HEALTH REPORT - DATE ' || to_char(sysdate, 'dd-Mon-yyy') from dual;
select '==============================================' from dual;
select 'LIST OF INVALID OBJECTS PER SCHEMA' from dual;
set heading on
column object_name format a30
column object_type format a20
column time_modification format a18
column status format a7
column date_created format a18
BREAK ON username skip 1 nodup  ON REPORT
COMPUTE count label '' OF object_name ON username
COMPUTE count LABEL TOTAL OF object_name ON REPORT
select du.username, do.object_type,do.object_name,date_created,time_modified
from dba_users du
left outer join (select owner
                       ,object_type                                  as object_type
                       ,object_name                                  as object_name
                       ,to_char(created, 'yyyymmdd hh24:mi:ss')      as date_created
                       ,to_char(last_ddl_time,'yyyymmdd hh24:mi:ss') as time_modified
                 from   dba_objects
                 where  status = 'INVALID') do on (do.owner = du.username)
where du.username in (${delimited_str})
order by 1 asc, 3 asc;
exit
EOSQL)
  echo "${hr}" >> "$lf"
}


(END)







































