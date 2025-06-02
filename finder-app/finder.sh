#!/bin/sh

# $1 as filedir
# $2 searchstr
#
#

set -e

if [ $# -ne 2 ]; then
  echo "Invalid number of arguments"
  echo "Usage: finder.sh filedir searchstr"
  exit 1
fi

if [ ! -d $1 ]; then
  echo "$1 is not a valid directory"
  exit 1
fi

NFILES=$(find $1 -name "*" | wc -l)
NFOUND=$(grep -r $2 $1 | wc -l)

echo "The number of files are $NFOUND and the number of matching lines are $NFOUND"

exit 0
