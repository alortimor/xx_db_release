#!/bin/bash

function die ()
{
  # Description: print error message and exit with supplied code
  # USAGE: die STATUS [ MESSAGE ]
  error=$1
  shift
  [ -n "$*" ] printf "%s\n" "$*" >&2
  exit "$error"
}

function usage()
{
  # Description: print usage info
  # USAGE: usage
  # REQUIRES: variables defined $scriptname $description $usage
  printf "%s - %s\n" "$scriptname" "$description"
  printf "usage %s\n" "$usage"
}

function version() {
  # Description: print version info
  # USAGE: version
  # REQUIRES: variables defined: $scriptname, $author and $version
  printf "%s version %s\n" "$scriptname" "$version"
  printf "by %s, %d\n" "$author" "${date_of_creation%%-*}"
}

(END)
























