#!/bin/bash

# Validate arguments

if [ -z $1 ]; then
  echo "!!!!! Database not entered. Aborting..."
  exit 1
fi
if [ -z $2 ]; then
  echo "!!!!! Database file not entered. Aborting..."
  exit 1
fi

DB=$1
DB_FILE=$2

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

echo "-- Importing $DB_FILE to $DB database"
if [[ $DB_FILE = *".gz"* ]]; then
  gunzip < $DB_FILE | $CURRENT_DIR/pg-psql.sh $DB
else
  $CURRENT_DIR/pg-psql.sh $DB < $DB_FILE
fi
