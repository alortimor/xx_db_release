!! Pete, please note: there are a couple of "typos" in here, but Ive left them exactly as found in the programme just in case !!


#!/bin/bash


function get_script_name() {
 echo ${0##*/}
 return 0
}

function is_in_str()
  # usage: is_in_str string_to_search_for string_to_search_in
  case $2 in
    *$1*) true ;;
    *) false ;;
  esac

# insrts a string into another string at the position specified
# $1 = string to insert into
# $2 = string to insert
# $3 = OPTIONAL position to perform insert. If no potiion specified then $2 appended to the end of $1
function ins_str()
{
  [ -z $3 ] && printf "%s\n" $1$2 && return 0
  [[ $3 =~ [^0-9]+ ]] && printf "%s\n" "Postion specified unrecognised" && return 1
  [ $3 -gt ${#1} ] && printf "%s\n" "Insert position is greater than the string length" && return 1
  [ $3 -eq 1 ] && printf "%s\n" $2$1 && return 0

  local pos
  ((pos=$3-1))
  local left=${1:0:$pos}
  local right=${1:$pos}
  printf "%s\n" "$left$2$right"
  return 0
}

# functions used to verify if a "string" is a valid shell variable name
# returns 0 if valid and 1 if not
function valid_var_name()
  case $1 in
    [!a-zA-Z_]* | *[!a-zA-Z_]*) return 1 ;;
  esac

function cap_word()
  case $1 in
    a*) _UPR=A ;; b*) _UPR=B ;; c*)_UPR=C ;; d*) _UPR=D ;;
    e*) _UPR=E ;; f*) _UPR=F ;; g*)_UPR=G ;; h*) _UPR=H ;;
    i*) _UPR=I ;; j*) _UPR=J ;; k*)_UPR=K ;; l*) _UPR=L ;;
    m*) _UPR=M ;; n*) _UPR=N ;; o*)_UPR=O ;; p*) _UPR=P ;;
    q*) _UPR=Q ;; r*) _UPR=R ;; s*)_UPR=S ;; t*) _UPR=T ;;
    u*) _UPR=U ;; v*) _UPR=V ;; w*)_UPR=W ;; x*) _UPR=X ;;
    y*) _UPR=Y ;; z*) _UPR=Z ;; *) _UPR=${1%${1#?}} ;;
  esac

function rep_str()
{
  # usgae: rep_str string number
  _REP=$1
  while [ ${#_REP} -lt $2 ]; do
    _REP=$_REP$_REP$_REP$_REP
  done
  _REP="${_REP:0:$2}"
}

funtion valint()
{
  [[ ${1#-} =~ [^0-9] ]] && return 1
  return 0
}

function trim()
{
  # usage: trim string_to_trim
  local var=$1
  local tmp

  echo "Length ${#var} $var"
  tmp="${var##*[! ]}"
  var="${var%$tmp}"
  tmp="${var%%[! ]*}"
  var="${var#$tmp}"
  echo "$var"
}

function arr_to_delimited_str() {
 # usage: arr_to_delimited_str ${array_name[@]}
 local seperator="','"
 local str=$(printf "${seperator}%s" "${@}'" )" 
 echo ${str#??}
}

(END)







































