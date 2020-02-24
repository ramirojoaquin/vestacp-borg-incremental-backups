#!/bin/bash

# Validate arguments

if [ -z $1 ]; then
  echo "!!!!! Database not entered. Aborting..."
  exit 1
fi

DB=$1

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/pg-setup.sh

pg_dump -h localhost -U $USER $DB
