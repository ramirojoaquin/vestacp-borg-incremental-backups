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

echo "-- Importing $DB_FILE to $DB database"
if [[ $DB_FILE = *".gz"* ]]; then
  gunzip < $DB_FILE | psql -U postgres $DB
else
  psql -U postgres $DB < $DB_FILE
fi
