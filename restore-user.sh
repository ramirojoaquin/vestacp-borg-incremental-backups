#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/config.ini

# This script will restore the given user from incremental backup.
USAGE="restore-user.sh 2018-03-25 user"

# Assign arguments
TIME=$1
USER=$2

# Set script start time
START_TIME=`date +%s`

# Set user repository
USER_REPO=$REPO_USERS_DIR/$USER

##### Validations #####

if [[ -z $1 || -z $2 ]]; then
  echo "!!!!! This script needs 2 arguments. Backup date and user name"
  echo "---"
  echo "Usage example:"
  echo $USAGE
  exit 1
fi

# Check if user repo exist
if [ ! -d "$USER_REPO/data" ]; then
  echo "!!!!! User $USER has no backup repository or no backup has been executed yet. Aborting..."
  exit 1
fi

# Check if backup archive date exist in user repo
if ! borg list $USER_REPO | grep -q $TIME; then
  echo "!!!!! Backup archive $TIME not found, the following are available:"
  borg list $USER_REPO
  echo "Usage example:"
  echo $USAGE
  exit 1
fi

# Check if vesta repo exist
if [ ! -d "$REPO_VESTA/data" ]; then
  echo "!!!!! Vesta has no backup repository or no backup has been executed yet. Aborting..."
  exit 1
fi

# Check if backup archive date exist in vesta repo
if ! borg list $REPO_VESTA | grep -q $TIME; then
  echo "!!!!! Backup archive $TIME not found in Vesta repo, the following are available:"
  borg list $REPO_VESTA
  echo "Usage example:"
  echo $USAGE
  exit 1
fi

echo "########## BACKUP ARCHIVE $TIME FOR USER $USER FOUND, PROCEEDING WITH RESTORE ##########"

read -p "Are you sure you want to restore user $USER with $TIME backup version? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  [[ "$0" = "$BASH_SOURCE" ]]
  echo
  echo "########## PROCESS CANCELED ##########"
  exit 1
fi

# Set dir paths
USER_DIR=$HOME_DIR/$USER
VESTA_USER_DIR=$VESTA_DIR/data/users/$USER
BACKUP_USER_DIR="${USER_DIR:1}"
BACKUP_VESTA_USER_DIR="${VESTA_USER_DIR:1}"

cd /

if ! borg list $REPO_VESTA::$TIME | grep -q $BACKUP_VESTA_USER_DIR; then
  echo "!!!!! Vesta user config files for $USER are not present in backup archive $TIME. Aborting..."
  exit 1
fi
echo "----- Restoring Vesta user files from backup $REPO_VESTA::$TIME to $VESTA_USER_DIR"
rm -fr $BACKUP_VESTA_USER_DIR
borg extract --list $REPO_VESTA::$TIME $BACKUP_VESTA_USER_DIR

echo "-- Vesta rebuild user"
v-rebuild-user $USER

if ! borg list $USER_REPO::$TIME | grep -q $BACKUP_USER_DIR; then
  echo "!!!!! User $USER files are not present in backup archive $TIME. Aborting..."
  exit 1
fi
echo "----- Restoring user files from backup $USER_REPO::$TIME"
rm -fr $BACKUP_USER_DIR
borg extract --list $USER_REPO::$TIME $BACKUP_USER_DIR

echo "-- Fixing web permissions"
chown -R $USER:$USER $USER_DIR/web

echo "----- Checking if there are databases to restore"
v-list-databases $USER | cut -d " " -f1 | awk '{if(NR>2)print}' | while read DB ; do
  echo "-- Restoring $DB"
  yes | $CURRENT_DIR/restore-db.sh $TIME $USER $DB
done

echo "-- Vesta rebuild user"
v-rebuild-user $USER

echo
echo "$(date +'%F %T') #################### USER $USER RESTORE COMPLETED ####################"

END_TIME=`date +%s`
RUN_TIME=$((END_TIME-START_TIME))

echo "-- Execution time: $(date -u -d @${RUN_TIME} +'%T')"
echo
