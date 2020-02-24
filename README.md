# Vesta Control Panel Borg Incremental Backups
A series of bash scripts to perform incremental backups of Vesta Control Panel users and server config, using Borg Backup as backend.

### The problem
Vesta CP provides by default a backup system, this backup system creates a tar for each user every day (by default 10 copies are saved), But this way of making backups has some disadvantages when you have a lot of users:
* Server overload. Earch time the backup is run, a complete copy of user files are saved.
* Disk space consumption. Each backup copy contains a full backup of the user files. So its very easy to run out of disk space.

### The solution
An incremental backup is one in which successive copies of the data contain only the portion that has changed since the preceding backup copy was made. This way you can store lot of backups points, without making a full backup each time.

Borg Backup does an excellent job making incremental backups. And provide very interesting features such as compression, encryption and good performance.
You can get more info at https://www.borgbackup.org/

# How the script collection works
The main backup script is designed to be run every day via cronjob. This script saves a snapshot of all users, server config and vesta directory into different Borg repositories.

This borg repositories are saved in `/backup` by default, organized in folders.

Then, different scripts are provided to automatically restore users, webs, mail domains or databases if needed.

Additionally, it is possible to archive users who are no longer active (they are saved into an offline archive directory), and in these users the incremental backups do not run. In this way we also save disk space.

# Install
I use Debian 9. I did not test it in other distros, but i think you should not find any major problem.

## Requirements
* Vesta CP running
* Borg backup

### 1- Borg install
```
apt update
apt install borgbackup
```

### 2- Install the scripts
In my case i save the scripts under `/root/scripts`.
To install the script collection run the following commands as root:
```
mkdir -p /root/scripts
cd /root/scripts
git clone https://github.com/ramirojoaquin/vestacp-borg-incremental-backups.git
```

### 3- Create directory to store logs:
```
mkdir -p /var/log/scripts/backup
```

### 4- Setup the cronjob
As root run:
```
crontab -e
```
And add the following cronjob:
```
0 4 * * * /root/scripts/vestacp-borg-incremental-backups/backup-execute.sh > /var/log/scripts/backup/backup_`date "+\%Y-\%m-\%d"`.log 2>&1
```
This cronjob will run `backup-execute.sh` every day at 4am. You can change the hour and the log locations.

# Scripts details

## Backup execution
The main backup script `./backup-execute.sh` is designed to be run every day via cronjob and it performs the following actions:

* Creates an incremental backup archive/point of all the databases, using one repository per user . Repos are stored in `/backup/borg/db/USER`
* Creates an incremental backup archive/point of all the users, using one repository per user . Repos are stored in `/backup/borg/home/USER`
* Creates an incremental backup archive/point of config dir `/etc` and save the repo in `/backup/borg/etc`
* Creates an incremental backup archive/point of vesta directory `/usr/local/vesta` and save the repo in `/backup/borg/vesta`
* Creates an incremental backup archive/point of custom scripts `/root/scripts` and save the repo in `/backup/borg/scripts`
* Sync backup folder with a second remote server if needed.

All the paths can be customized in `config.ini` configuration file.

If no backup was executed yet, the script will initialize the corresponding borg repositories.

The name of the backup point/archive is set in the following format:
`2018-05-20` (year-month-day)

Vesta CLI commands are used to obtain all the information.

### Dump databases
`./dump-databases.sh`

Dump all databases and adds them to the user's db borg repository. It does this using pipes so that it does not use any temporary disk space.

This script is called by main `backup-execute.sh` but it can also be run independently, optionally adding the date in YYYY-MM-DD format as the first parameter.

## Backup restore usage

### Restore entire user
`./restore-user.sh 2018-03-25 user`

This script will restore the given user from a particular point in incremental backup. If the user exist is overwritten. If the user does not exist a new one is created.

* First argument is the archive/point, using the format YEAR-MONTH-DAY.
* Second argument is the username.

### Restore web domain (optional with database)
`./restore-web.sh 2018-03-25 user domain.com database`

This script will restore the given web domain from a particular point in incremental backup. The web domain must exist in the system.

* First argument is the archive/point, using the format YEAR-MONTH-DAY.
* Second argument is the username who owns the domain.
* Third argument is the web domain.
* Fourth argument is database name. This argument is optional.

### Restore database
`./restore-db.sh 2018-03-25 user database`

This script will restore the given database from a particular point in incremental backup. The database must exist in the system.

* First argument is the archive/point, using the format YEAR-MONTH-DAY.
* Second argument is the username who owns the database.
* Third argument is the database name.

### Restore mail domain
`./restore-mail.sh 2018-03-25 user domain.com`

This script will restore the given mail domain from a particular point in incremental backup. The mail domain must exist in the system.

* First argument is the archive/point, using the format YEAR-MONTH-DAY.
* Second argument is the username who owns the mail domain.
* Third argument is the mail domain.

## Offline archive scripts

### Archive user
`./archive-user.sh user`

This script will save a copy of the given user to the offline archive directory `/backup/offline`.
The databases are stored into the user dir. Using the following format `/home/userdir/db_dump/database.sql.gz`

* First argument is the user name.

### Restore archived user
`./restore-archived-user.sh user`

This script is similar to restore-user.sh, but instead of restore from incremental backup, it will restore the given user from the offline archive.

If the user does not exist in the system, it will be created.

If the user already exist, it will be overwrited.

* First argument is the user name.

## Cleaning and disk space saving scripts

### Purge user backup
`./purge-user-backup.sh user`

This script will remove all incremental backups archives/points for the given user.

* First argument is the user name.

### Clean user repositories
`./clean-user-repos.sh`

This script performs a comparison between user repositories and current active users.

If a repository does not correspond to an active user. The following actions are executed
* The user repo is extracted into the offline archive directory `/backup/offline` for future use.
* The user repo is deleted from the user repo dir saving disk space.

# Other useful commands

You can use borg cli to check backups and manually restore.

Full documentation is available here: https://borgbackup.readthedocs.io/en/stable/index.html#

For exmaple this command will list the available incremental backup points for user admin.
`borg list /backup/borg/home/admin`

# Personal note

This is my first git project. I want to share this with all the community. Use it under your own responsability.

I am also open to changes and suggestions. You can write me to ramirojoaquin@gmail.com.
