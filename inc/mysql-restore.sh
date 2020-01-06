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

# Check if database and database file exist

DBEXISTS=$(mysql --batch --skip-column-names -e "SHOW DATABASES LIKE '"$DB"';" | grep "$DB" > /dev/null; echo "$?")
if ! [ $DBEXISTS -eq 0 ]; then
  echo "!!!!! Database $DB does not exists. Aborting..."               
  exit 1
fi
if [ -z $DB_FILE ]; then
  echo "!!!!! Database file $DB_FILE not found. Aborting..."      
  exit 1
fi

echo "-- Removing database $DB"
mysqladmin -f drop $DB

echo "-- Creating database $DB"
mysql -e "CREATE DATABASE IF NOT EXISTS $DB"

echo "-- Importing $DB_FILE to $DB database"
if [[ $DB_FILE = *".gz"* ]]; then
  gunzip < $DB_FILE | mysql $DB
else
  mysql $DB < $DB_FILE
fi
