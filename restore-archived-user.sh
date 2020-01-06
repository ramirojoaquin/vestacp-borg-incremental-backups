#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/config.ini

# This script will restore the given user from the offline archive.
# If the user does not exist in the system, it will be created.
# If the user already exist, it will be overwritten.
USAGE="restore-archived-user.sh user"

# Assign arguments
USER=$1

# Set script start time
START_TIME=`date +%s`

# Temp dir setup
TEMP_DIR=$CURRENT_DIR/tmp
mkdir -p $TEMP_DIR

# Set dir paths
USER_DIR=$HOME_DIR/$USER
VESTA_USER_DIR=$VESTA_DIR/data/users/$USER
ARCHIVE_USER_DIR=$ARCHIVE_DIR/$USER
ARCHIVE_VESTA_USER_DIR=$ARCHIVE_USER_DIR/vesta/$USER

##### Validations #####

if [[ -z $1 ]]; then
  echo "!!!!! This script needs 1 argument: User name"
  echo "---"
  echo "Usage example:"
  echo $USAGE
  exit 1
fi

# Check if user archive exist
if [ ! -f "$ARCHIVE_USER_DIR.tar.gz" ]; then
  echo "!!!!! User $USER has no offline archive file in $ARCHIVE_DIR. Aborting..."
  exit 1
fi

echo "########## OFFLINE ARCHIVE FOR USER $USER FOUND ##########"

# Check if user exist in the system
if [ -d "$VESTA_USER_DIR" ]; then
  echo "!!!!! User $USER already exist in the system."
  read -p "Are you sure you want to overwrite the user $USER with offline archived version stored in $ARCHIVE_USER_DIR.tar.gz? " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    [[ "$0" = "$BASH_SOURCE" ]]
    echo
    echo "########## PROCESS CANCELED ##########"
    exit 1
  fi
else
  # Ask for confirmation
  read -p "Are you sure you want to create the user $USER using offline archived version stored in $ARCHIVE_USER_DIR.tar.gz? " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    [[ "$0" = "$BASH_SOURCE" ]]
    echo
    echo "########## PROCESS CANCELED ##########"
    exit 1
  fi
fi

echo
echo "########## Extracting offline archive file $ARCHIVE_USER_DIR.tar.gz ##########"
cd $ARCHIVE_DIR
tar -pxzf $USER.tar.gz

# Archive content validation
if [ ! -d "$ARCHIVE_VESTA_USER_DIR" ]; then
  echo "!!!!! User $USER vesta config files are not present in the offline archive. Aborting..."
  exit 1
fi
if [ -z "$(ls -A $ARCHIVE_VESTA_USER_DIR)" ]; then
  echo "!!!!! Restored Vesta user config dir from offline archive is empty, Aborting..."
  exit 1
fi

echo "########## BACKUP OFFLINE ARCHIVE FOR USER $USER FOUND, PROCEEDING WITH RESTORE ##########"

echo "-- Restoring vesta config files for user $USER from $ARCHIVE_VESTA_USER_DIR to $VESTA_USER_DIR"
mkdir -p $VESTA_USER_DIR
rsync -za --delete $ARCHIVE_VESTA_USER_DIR/ $VESTA_USER_DIR/

echo "-- Vesta rebuild user"
v-rebuild-user $USER

# First we remove vesta folder from archive
if [ -d "$ARCHIVE_USER_DIR/vesta" ]; then
  rm -rf $ARCHIVE_USER_DIR/vesta
fi

echo "-- Restoring user files from $ARCHIVE_USER_DIR to $USER_DIR"
rsync -za --delete --omit-dir-times $ARCHIVE_USER_DIR/ $USER_DIR/

echo "-- Fixing web permissions"
chown -R $USER:$USER $USER_DIR/web

echo "----- Checking if there are databases to restore"
v-list-databases $USER | grep \ mysql\  | cut -d " " -f1 | while read DB ; do
  DB_DIR=$HOME_DIR/$USER/$DB_DUMP_DIR_NAME
  DB_FILE=$DB_DIR/$DB.sql.gz
  # Check if there is a backup for the db
  if test -f "$DB_FILE"
    then
    echo "-- $DB found in offline archive"
    $CURRENT_DIR/inc/db-restore.sh $DB $DB_FILE
  else
    echo "$DB_FILE not found offline archive in $DB_DIR"
  fi
done

echo "-- Vesta rebuild user"
v-rebuild-user $USER

echo "----- Cleaning extracted offline archive dir"
if [ -d "$ARCHIVE_USER_DIR" ]; then
  rm -rf $ARCHIVE_USER_DIR
fi

echo
echo "$(date +'%F %T') #################### USER $USER RESTORE FROM OFFLINE ARCHIVE $ARCHIVE_USER_DIR.tar.gz COMPLETED ####################"

END_TIME=`date +%s`
RUN_TIME=$((END_TIME-START_TIME))

echo "-- Execution time: $(date -u -d @${RUN_TIME} +'%T')"
echo
