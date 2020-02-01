#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/config.ini

# This script dump all databases to the user's database borg repo

# Assign arguments
TIME=$1
DB_COUNT=0

echo "$(date +'%F %T') #################### DUMP MYSQL DATABASES TO CORRESPONDING USER BORG REPO ####################"
# Get user list
while read USER ; do
  USER_REPO=$REPO_DB_DIR/$USER
  # Check if repo was initialized, if its not we perform borg init
  if ! [ -d "$USER_REPO/data" ]; then
    echo "-- No repo found. Initializing new borg repository $USER_REPO"
    mkdir -p $USER_REPO
    borg init $OPTIONS_INIT $USER_REPO
  fi
  # Get MySQL databases
  while read DATABASE ; do
    ARCHIVE="$DATABASE-$TIME"
    echo "-- Creating new backup archive $USER_REPO::$ARCHIVE"
    mysqldump $DATABASE --opt --routines --skip-comments | borg create $OPTIONS_CREATE $USER_REPO::$ARCHIVE -
    borg prune $OPTIONS_PRUNE $USER_REPO --prefix ${DATABASE}'-'
    let DB_COUNT++
  done < <(v-list-databases $USER | grep -w mysql | cut -d " " -f1)
  # Get PostgreSQL databases
  while read DATABASE ; do
    ARCHIVE="$DATABASE-$TIME"
    echo "-- Creating new backup archive $USER_REPO::$ARCHIVE"
    $CURRENT_DIR/inc/pg-pgdump.sh $DATABASE | borg create $OPTIONS_CREATE $USER_REPO::$ARCHIVE -
    borg prune $OPTIONS_PRUNE $USER_REPO --prefix ${DATABASE}'-'
    let DB_COUNT++
  done < <(v-list-databases $USER | grep -w pgsql | cut -d " " -f1)

  echo "-- Cleaning old backup archives"
done < <(v-list-users | cut -d " " -f1 | awk '{if(NR>2)print}')

echo "$(date +'%F %T') ########## $DB_COUNT DATABASES SAVED ##########"
echo
