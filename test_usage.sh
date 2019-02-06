#!/bin?bash
function usage() {
  printf "%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n" "usage: xxrbsdep.sh [Atrh] -x xmlfile -i release_info.dat "\
    "-A Oracle script files are applied in file name alphabetical order (default)"\
    "-t Oracle script files are applied in file date/time ascending order"\
    "-r Oracle script files applied in reverse order, combined with -A or -t"\
    "-x xml file - processing metadata required; e.g.; " \
            "<all>" \
            " <oradata tdID='1' dName='./Database/APPS' owner='APPS' sOwner1='XXRBS_ODI_APPUSER' dbL1='' sOwner2='' dbL2'' />" \
            " <oradataa tdID='2' dName='./Database/XXRBS' owner='XXRBS' dbLog='yes' /> "\
            " <linuxdirs>"\
	    "   <dir tdID='1' dID='1' dName='./Database/APPS/DDL/Create/Tables' customOrder='yes'>"\
            "     <sqlfile fID='1' fName='tst_tb13.sql' />"\
            "     <sqlfile fID='2' fName='tst_tb12.sql' />"\
            "   </dir>"\
            "   <dir tdID='2' dID='2' dName='./Database/XXRBS/DML/Insert' customOrder='></dir>"\
            "   <dir tdID='1' dID='3' dName='./Database/APPS/DDL/Create/Synonyms' customOrder='no'></dir>"\
            "   <dir tdID='1' dID='4' dName='./Database/APPS/DCL/Grant' customOrder='yes'>"\
            "     <sqlfile fID='1' fName='xla_distribution_links.sql' />"\
            "   </dir>"\
            " </linuxdirs>"\
            "</all>"\
    "-i Release info (release_info.dat) listing release specific variables"\
    "-h help"
}

usage

(END)
