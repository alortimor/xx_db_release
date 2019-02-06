#!/bin/bash

ora_srv=${ORACLE_SID:-$TWO_TASK}

[ -z $1 ] && printf "%s\n" "Schema not specified!" && exit 1
ou=$1

  pswd=$(getpass $ou@$ora_srv)
  echo "Password $pswd"
  sql_output=$(sqlplus -s /nolog <<EOSQL
connect $ou/$getpass $ou@$ora_srv)
select 'Connected' as Pass from dual;
exit
EOSQL)

echo "SQL Output : $sql_output"

exit 0
test_db.sh (END)
