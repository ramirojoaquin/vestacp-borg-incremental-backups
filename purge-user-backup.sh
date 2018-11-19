#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/config.ini

# This script will remove incremental backups for the given user.
USAGE="purge-user-backup.sh user"

# Assign arguments
USER=$1

# Set script start time
START_TIME=`date +%s`

# Set user repository
USER_REPO=$REPO_USERS_DIR/$USER

##### Validations #####

if [ -z $1 ]; then
  echo "!!!!! This script needs 1 argument: user"
  echo "---"
  echo "Usage example:"
  echo $USAGE
  exit 1
fi

# Check if user repo exist
if [ ! -d "$USER_REPO" ]; then
  echo "!!!!! User $USER has no backup repository or no backup has been executed yet. Aborting..."
  echo "---"
  echo "Available user repositories:"
  ls $REPO_USERS_DIR
  echo "---"
  echo "Usage example:"
  echo $USAGE
  exit 1
fi

echo "########## BACKUP REPOSITORY FOR USER $USER FOUND, PROCEEDING WITH PURGE ##########"

echo "!!!!! This will remove all incremental backups for user $USER."
read -p "Are you sure you want to purge $USER_REPO repository? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  [[ "$0" = "$BASH_SOURCE" ]]
  echo
  echo "########## PROCESS CANCELED ##########"
  exit 1
fi
echo "-- Removing user $USER repo: $USER_REPO"
if [ -d "$USER_REPO" ]; then
  rm -rf $USER_REPO
fi

echo "If the user still exist in the system the incremental backups will begin in the next run."

echo
echo "$(date +'%F %T') #################### USER $USER REPOSITORY PURGE COMPLETE ####################"

END_TIME=`date +%s`
RUN_TIME=$((END_TIME-START_TIME))

echo "-- Execution time: $(date -u -d @${RUN_TIME} +'%T')"
echo
