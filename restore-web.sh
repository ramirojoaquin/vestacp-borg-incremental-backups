#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/config.ini

# This script will restore a web domain from incremental backup
USAGE="restore-web.sh 2018-03-25 user domain.com database"

# Assign arguments
TIME=$1
USER=$2
WEB=$3

# Set script start time
START_TIME=`date +%s`

# Set user repository
USER_REPO=$REPO_USERS_DIR/$USER

##### Validations #####

if [[ -z $1 || -z $2 || -z $3 ]]; then
  echo "!!!!! This script needs at least 3 arguments. Backup date, user name and web domain. Database is optional"
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

if [ ! -d "$HOME_DIR/$USER/web/$WEB" ]; then
  echo "!!!!! The web domain $WEB does not exist under user $USER."
  echo "---"
  echo "User $USER has the following available web domains:"
  ls $HOME_DIR/$USER/web
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


echo "########## BACKUP ARCHIVE $TIME FOUND, PROCEEDING WITH RESTORE ##########"

read -p "Are you sure you want to restore web $WEB owned by $USER with $TIME backup version? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  [[ "$0" = "$BASH_SOURCE" ]]
  echo
  echo "########## PROCESS CANCELED ##########"
  exit 1
fi

# Set dir paths
WEB_DIR=$HOME_DIR/$USER/web/$WEB/$PUBLIC_HTML_DIR_NAME
BACKUP_WEB_DIR="${WEB_DIR:1}"

if ! borg list $USER_REPO::$TIME | grep -q $BACKUP_WEB_DIR; then
  echo "!!!!! $WEB is not present in backup archive $TIME. Aborting..."
  exit 1
fi
echo "-- Restoring web domain files from backup $USER_REPO::$TIME to $WEB_DIR"
cd /
rm -fr $BACKUP_WEB_DIR
borg extract --list $USER_REPO::$TIME $BACKUP_WEB_DIR

echo "-- Fixing permissions"
chown -R $USER:$USER $WEB_DIR/

# Check if database argument is present and proceed with database restore

if [ $4 ]; then
  DB=$4
  v-list-databases $USER | cut -d " " -f1 | awk '{if(NR>2)print}' | while read DATABASE ; do
    if [ "$DB" == "$DATABASE" ]; then
      echo "-- Restoring database $DB from backup $TIME"
      yes | $CURRENT_DIR/restore-db.sh $TIME $USER $DB
    else
      echo "!!!!! Database $DB not found under selected user. User $USER has the following databases:"
      v-list-databases $USER | cut -d " " -f1 | awk '{if(NR>2)print}'
    fi
  done
fi

echo
echo "$(date +'%F %T') ########## WEB $WEB OWNED BY $USER RESTORE COMPLETED ##########"

END_TIME=`date +%s`
RUN_TIME=$((END_TIME-START_TIME))

echo "-- Execution time: $(date -u -d @${RUN_TIME} +'%T')"
echo
