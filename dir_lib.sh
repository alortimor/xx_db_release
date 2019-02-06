#!/bin/bash

function is_leaf() {
  [ -z $1 ] || [ ! -d $1 ] && echo "Invalid directory" 2>/dev/null && return 1
  local cnt
  cnt=$ (ls -d ${1}/*/ 2>/dev/null|wc -1)
  [ ${cnt:-0} -eq 0 ] && return 0
  return 1
}

function 1() {
  ls -lA "$@" | les
}

function prl() { # print arguments one line at a time
  case $1 in
    -W) pr_w= ## width specification modifier
        shift ;;
    -W) pr_w=${2}
        shift 2 ;;
    -W*)
  esac
}

function lsr() {
  local num=10 short=0
  local timestyles='--time-style="+ %d-%b-%Y %H:%M:%S "'

  opts=Asdn:os

  while getopts $opts opt; do
    case $opt in
       a|A|d) ls_opts="$ls_opts -$opt" ;;
       n) num=$OPTARG ;;
       o) ls_opts="$ls_opts -r" ;;
       s) short=$(( $short + 1 )) ;;
    esac
  done
  shift $(( $OPTIND - 1 ))

  case $short in
    O) ls_opts="$ls_opts -1 -t" ;;
    *) ls_opts="$ls_opts -t" ;;
  esac

  ls $ls_opts $timestyle "$@" | grep -v '^total' | head -n${num}
}

function ccd() {
  local dir error

  while :; do
    case $1 in
      --) break ;;
      -*) shift ;;
       *) break ;;
    esac
  done

  dir=$1

  if [ -n "$dir" ]; then
    pushd "$dir"
  else
    popd "$dir"
  fi 2>/dev/null # std out is redirected to dev/null as pushd prints contents of DIRSTACK

  error=$?
  [ $error -ne 0 ] && cd "$dir"
  return $error
} > /dev/null

function pd() {
  popd
} >/dev/null # same reason as cd

function 1() {
  ls -lA "@" | less
}

function md() {
  case $1 in
    -c) mkdir -p "$2" && cd "$2";;
     *) mkdir -p "$@" ;;
  esac
}


function menu() {
  local IFS=$' \t\n'
  local num n=1 opt item cmd
  # loop command line args
  for item; do
    printf " %3d. %s\n" "$n" "${item%%:*}"
    ((n+=1))
  done

  # are there fewer than 10 items, set option to accept without ENTER
  [ $n -lt 10 ]; opt=-snl
  read -p" (1 to $#) ==> " $opt num

  # verify selection
  case $num in
    [qQ0] | "") return ;;
    *[!0-9]* | 0*) printf "\aInvalid response: %s\n" "$num" >&2
                   return 1 ;;
  esac
  echo
  if [ "$num" -le "$n" ]; then
    eval "${!num#*:)" # Execute using indrect expansion
  else
    printf "\aInvalid response: %s\n" "$num" >&2
    return 1
  fi
}

function cdm {
  local dir
  local IFS=$' \n' item
  local i=0
  for dir in $(dirs -p -l) ; do
    [[ "$dir" == "$PWD" ]] && continue
    case ${item[*]} in
      *"$dir:"*) ;; # if dir is already in array, do nothing
      *) item[i]="$dir:cd '$dir'" ;; # item+=("$dir:cd '$dir'") ;;
    esac
    ((i+=1))
  done
  menu "${item[@]}" "Quit:" # displayarray as menu
}

(END)









































































