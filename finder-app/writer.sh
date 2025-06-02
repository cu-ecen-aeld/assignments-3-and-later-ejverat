#!/bin/sh

# $1 as writefile
# $2 writestr
#
#

set -e

if [ $# -ne 2 ]; then
  echo "Invalid number of arguments"
  echo "Usage: writer.sh writefile writestr"
  exit 1
fi

DIR=$(dirname $1)

mkdir -p $DIR

$(echo $2 >$1)

exit 0
