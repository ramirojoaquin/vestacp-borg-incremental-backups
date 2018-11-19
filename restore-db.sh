#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/config.ini

# This script will restore a database from incremental backup.
USAGE="restore-db.sh 2018-03-25 user database"

# Assign arguments
TIME=$1
USER=$2
DB=$3

# Set script start time
START_TIME=`date +%s`

# Temp dir setup
TEMP_DIR=$CURRENT_DIR/tmp
mkdir -p $TEMP_DIR

# Set user repository
USER_REPO=$REPO_USERS_DIR/$USER

##### Validations #####

if [[ -z $1 || -z $2 || -z $3 ]]; then
  echo "!!!!! This script needs at least 3 arguments. Backup date, user name and dadabase"
  echo "---"
  echo "Usage example:"
  echo $USAGE
  exit 1
fi

if [ ! -d "$HOME_DIR/$USER" ]; then
  echo "!!!!! User $USER does not exist"
  echo "---"
  echo "Available users:"
  ls $HOME_DIR
  echo "---"
  echo "Usage example:"
  echo $USAGE
  exit 1
fi

if [[ $(v-list-databases $USER | cut -d " " -f1 | awk '{if(NR>2)print}' | grep "$DB") != "$DB" ]]; then
  echo "!!!!! Database $DB not found under selected user."
  echo "---"
  echo "User $USER has the following databases:"
  v-list-databases $USER | cut -d " " -f1 | awk '{if(NR>2)print}'
  echo "---"
  echo "Usage example:"
  echo $USAGE
  exit 1
fi

if [ ! -d "$USER_REPO/data" ]; then
  echo "!!!!! User $USER has no backup repository or no backup has been executed yet. Aborting..."
  exit 1
fi

if ! borg list $USER_REPO | grep -q $TIME; then
  echo "!!!!! Backup archive $TIME not found, the following are available:"
  borg list $USER_REPO
  echo "Usage example:"
  echo $USAGE
  exit 1
fi


echo "########## BACKUP ARCHIVE $TIME FOUND, PROCEEDING WITH DATABASE RESTORE ##########"
echo
read -p "Are you sure you want to restore database $DB owned by $USER with $TIME backup version? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  [[ "$0" = "$BASH_SOURCE" ]]
  echo
  echo "########## PROCESS CANCELED ##########"
  exit 1
fi

cd $TEMP_DIR
echo "-- Restoring database $DB from backup $USER_REPO::$TIME"
DB_DIR=$HOME_DIR/$USER/$DB_DUMP_DIR_NAME
BACKUP_DB_DIR="${DB_DIR:1}"
borg extract --list $USER_REPO::$TIME $BACKUP_DB_DIR
# Check that the files have been restored correctly
DB_FILE=$BACKUP_DB_DIR/$DB.sql.gz
if [ ! -f "$DB_FILE" ]; then
  echo "!!!!! Database $DB file is not present in backup archive $TIME. Aborting..."
  exit 1
else
  $CURRENT_DIR/inc/db-restore.sh $DB $DB_FILE
fi

echo "----- Cleaning temp dir"
if [ -d "$TEMP_DIR" ]; then
  rm -rf $TEMP_DIR/*
fi

echo
echo "$(date +'%F %T') ########## DATABASE $DB OWNED BY $USER RESTORE COMPLETED ##########"

END_TIME=`date +%s`
RUN_TIME=$((END_TIME-START_TIME))

echo "-- Execution time: $(date -u -d @${RUN_TIME} +'%T')"
echo
