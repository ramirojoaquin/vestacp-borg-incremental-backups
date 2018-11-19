#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/config.ini

# This script will save a copy of the given user to the offline archive directory
USAGE="restore-user.sh user"

# Assign arguments
USER=$1

# Set script start time
START_TIME=`date +%s`

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
if [ ! -d "$USER_DIR" ]; then
  echo "!!!!! User $USER does not exist in the system. Aborting..."
  exit 1
fi

# Check if user exist in vesta dir
if [ ! -d "$VESTA_USER_DIR" ]; then
  echo "!!!!! User $USER doest not exist in vesta directory."
  exit 1
fi

# Check if user archive exist
if [ -f "$ARCHIVE_USER_DIR.tar.gz" ]; then
  echo "!!!!! User archive file $ARCHIVE_USER_DIR.tar.gz already exist."
  read -p "Do you want to overwrite? " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    [[ "$0" = "$BASH_SOURCE" ]]
    echo
    echo "########## PROCESS CANCELED ##########"
    exit 1
  fi
fi

if [ -d "$ARCHIVE_USER_DIR" ]; then
  echo "!!!!! User archive directory $ARCHIVE_USER_DIR already exist."
  read -p "Do you want to overwrite? " -n 2 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    [[ "$0" = "$BASH_SOURCE" ]]
    echo
    echo "########## PROCESS CANCELED ##########"
    exit 1
  fi
fi

echo "########## USER $USER FOUND, PROCEEDING WITH ARCHIVE ##########"

echo "-- Dumping databases to user dir"
while read DATABASE ; do
  # Create dir where the user databases will be stored
  DESTINATION=$HOME_DIR/$USER/$DB_DUMP_DIR_NAME
  mkdir -p $DESTINATION
  # Clean destination
  rm -f $DESTINATION/*
  mysqldump $DATABASE --opt --routines | gzip > $DESTINATION/$DATABASE.sql.gz
  echo "$(date +'%F %T') -- $DATABASE > $DESTINATION/$DATABASE.sql.gz"
  # Fix permissions
  chown -R $USER:$USER $DESTINATION
done < <(v-list-databases $USER | cut -d " " -f1 | awk '{if(NR>2)print}')

echo "-- Creating user archive directory $ARCHIVE_USER_DIR"
# First remove archive dir and file if exist
if [ -d "$ARCHIVE_USER_DIR" ]; then
  rm -rf $ARCHIVE_USER_DIR
fi
if [ -f "$ARCHIVE_USER_DIR.tar.gz" ]; then
  rm -rf $ARCHIVE_USER_DIR.tar.gz
fi

# Archive dir creation
mkdir -p $ARCHIVE_USER_DIR
mkdir -p $ARCHIVE_VESTA_USER_DIR

echo "-- Saving vesta config files for user $USER from $VESTA_USER_DIR to $ARCHIVE_VESTA_USER_DIR"
rsync -za $VESTA_USER_DIR/ $ARCHIVE_VESTA_USER_DIR/

echo "-- Saving user files from $USER_DIR to $ARCHIVE_USER_DIR"
rsync -za $USER_DIR/ $ARCHIVE_USER_DIR/

echo "-- Compressing $ARCHIVE_USER_DIR into $ARCHIVE_USER_DIR.tar.gz"
cd $ARCHIVE_DIR
tar -pczf $USER.tar.gz $USER

# Clean archive dir
if [ -d "$ARCHIVE_USER_DIR" ]; then
  rm -rf $ARCHIVE_USER_DIR
fi

echo
echo "$(date +'%F %T') #################### USER $USER ARCHIVED INTO $ARCHIVE_USER_DIR.tar.gz ####################"

END_TIME=`date +%s`
RUN_TIME=$((END_TIME-START_TIME))

echo "-- Execution time: $(date -u -d @${RUN_TIME} +'%T')"
echo
