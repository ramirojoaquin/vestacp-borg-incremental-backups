#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/config.ini
echo
echo "This script performs a comparison between user repositories and current active users."
echo "If a repository does not correspond to an active user. The following actions are executed:"
echo "-- The user repo is extracted into the offline archive directory $ARCHIVE_DIR for future use."
echo "-- The user repo is deleted from the user repo dir saving disk space."
echo

# Set script start time
START_TIME=`date +%s`

# Set array of user repos
USER_REPOS_TO_ARCHIVE=()

# Temp dir setup
TEMP_DIR=$CURRENT_DIR/tmp
mkdir -p $TEMP_DIR

for USER_REPO in $REPO_USERS_DIR/* ; do
  USER=$(basename $USER_REPO)
  if [ ! -d "$HOME_DIR/$USER" ]
  then
    USER_REPOS_TO_ARCHIVE+=($USER)
  fi
done

if [ ${#USER_REPOS_TO_ARCHIVE[@]} -eq 0 ]; then
  echo "########## NO USER REPOSITORIES TO CLEAN ##########"
  echo
  exit 1
fi

echo "########## THE FOLLOWING USER REPOSITORIES DOES NOT HAVE AN ACTIVE USER IN THE SYSTEM ##########"
echo
printf '%s\n' "${USER_REPOS_TO_ARCHIVE[@]}"

echo

read -p "Are you sure you want to archive this user repositories into $ARCHIVE_DIR? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  [[ "$0" = "$BASH_SOURCE" ]]
  echo
  echo "########## PROCESS CANCELED ##########"
  exit 1
fi

echo

for USER in "${USER_REPOS_TO_ARCHIVE[@]}"
do
  echo "########## Processing user $USER ##########"
  echo

  USER_REPO=$REPO_USERS_DIR/$USER
  LAST_BACKUP_ARCHIVE=$(borg list $USER_REPO | cut -d " " -f1 | awk 'END{print}')

  # Set dir paths
  ARCHIVE_USER_DIR=$ARCHIVE_DIR/$USER
  USER_DIR=$HOME_DIR/$USER
  BACKUP_USER_DIR="${USER_DIR:1}"
  VESTA_USER_DIR=$VESTA_DIR/data/users/$USER
  BACKUP_VESTA_USER_DIR="${VESTA_USER_DIR:1}"
  ARCHIVE_VESTA_USER_DIR=$ARCHIVE_USER_DIR/vesta

  if [ -f "$ARCHIVE_USER_DIR.tar.gz" ]; then
    echo "!!!!! User archive file $ARCHIVE_USER_DIR.tar.gz already exist."
    read -p "Do you want to overwrite? " -n 2 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
      [[ "$0" = "$BASH_SOURCE" ]]
      echo
      echo "########## PROCESS CANCELED ##########"
      continue
    fi
  fi

  if [ -d "$ARCHIVE_USER_DIR" ]; then
    echo "!!!!! User archive directory $ARCHIVE_USER_DIR already exist."
    read -p "Do you want to overwrite? " -n 3 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
      [[ "$0" = "$BASH_SOURCE" ]]
      echo
      echo "########## PROCESS CANCELED ##########"
      continue
    fi
  fi

  if [ -z "$LAST_BACKUP_ARCHIVE" ]; then
    echo "!!!!! No backup archive found, cancel user $USER process"
    continue
    echo
  fi

  echo "-- Creating archive user dir $ARCHIVE_USER_DIR"
  mkdir -p $ARCHIVE_USER_DIR
  mkdir -p $ARCHIVE_VESTA_USER_DIR
  cd $TEMP_DIR

  echo "-- Extracting Vesta user $USER files from backup $REPO_VESTA::$LAST_BACKUP_ARCHIVE to temp dir"
  borg extract --list $REPO_VESTA::$LAST_BACKUP_ARCHIVE $BACKUP_VESTA_USER_DIR
  # Check that the files have been restored correctly
  if [ ! -d "$BACKUP_VESTA_USER_DIR" ]; then
    echo "!!!!! Vesta user config files for $USER are not present in backup archive $LAST_BACKUP_ARCHIVE."
  fi
  if [ -z "$(ls -A $BACKUP_VESTA_USER_DIR)" ]; then
    echo "!!!!! Vesta user config files restored directory for $USER is empty."
  fi

  echo "-- Extracting last backup $USER_REPO::$LAST_BACKUP_ARCHIVE to temp dir"
  borg extract --list $USER_REPO::$LAST_BACKUP_ARCHIVE $BACKUP_USER_DIR

  # Check that the files have been restored correctly
  if [ ! -d "$BACKUP_USER_DIR" ]; then
    echo "!!!!! User $USER files are not present in backup archive $LAST_BACKUP_ARCHIVE."
    continue
  fi
  if [ -z "$(ls -A $BACKUP_USER_DIR)" ]; then
    echo "!!!!! User $USER restored directory is empty."
    continue
  fi

  echo "-- Moving user files from temp dir to $ARCHIVE_USER_DIR"
  mv $BACKUP_USER_DIR/* $ARCHIVE_USER_DIR
  mv $BACKUP_VESTA_USER_DIR $ARCHIVE_VESTA_USER_DIR

  echo "-- Compressing $ARCHIVE_USER_DIR to $ARCHIVE_DIR/$USER.tar.gz"
  cd $ARCHIVE_DIR
  tar -pczf $USER.tar.gz $USER

  # Clean archive dir
  if [ -d "$ARCHIVE_USER_DIR" ]; then
    rm -rf $ARCHIVE_USER_DIR
  fi

  echo "-- Removing user repo $USER_REPO from disk."
  if [ -d "$USER_REPO" ]; then
    rm -rf $USER_REPO
  fi

  echo
done

echo "-- Cleaning temp dir"
if [ -d "$TEMP_DIR" ]; then
  rm -rf $TEMP_DIR/*
fi

echo
echo "$(date +'%F %T') #################### USER REPOSITORIES CLEAN COMPLETED ####################"

END_TIME=`date +%s`
RUN_TIME=$((END_TIME-START_TIME))

echo "-- Execution time: $(date -u -d @${RUN_TIME} +'%T')"
echo
