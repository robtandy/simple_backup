#!/bin/bash

#Directory of this script
DIR=$(cd $(dirname "$0"); pwd)

# root directory of backup script and tree
BACKUP_ROOT=$DIR/../

# location of backups
BU_LOCATION=${BACKUP_ROOT}/servers/
# location of logs
LOG_LOCATION=${BACKUP_ROOT}/logs/
# location of most current backups by server
CURRENTS=${BACKUP_ROOT}/currents/
# number of backups to keep
KEEP=5
# option to make hard links for backups, this is _important_ if you want
# to be efficient on space.
LINK_OPTION="--link-dest="

# getConfig
#
# takes a single parameter as the path to the config file containing
# valid bash code which sets the variables SERVER_NAME, EXCLUDES, and 
# BACKUP_DIR
# 
# This function will set the variable EXCLUDE to be a proper rsync 
# exclude option list
getConfig() {
    SERVER_FILE=$1
    . $SERVER_FILE

    EXCLUDE=""
    for i in $EXCLUDES 
    do 
        EXCLUDE="--exclude=$i $EXCLUDE"
    done
}

# backupServer
#
# takes a single argument to the config file representing the backup
# of one server

backupServer() {
  CONFIG_FILE=$1
  
  getConfig $CONFIG_FILE
  #
  # at this point, we should have the variables EXCLUDE, BACKUP_DIR, and
  # SERVER_NAME available to us
  #

  SERVER=$SERVER_NAME
  BUDIR=$BACKUP_DIR

  DATE=$(date "+%Y-%m-%d_%H:%M:%S")
  # replace slashes in name of directory to back up with _'s
  # so if this script was called with /home/rob, replace it with 
  # _home_rob this way we can see a single directory in the backups
  # directory with the name of the remote location we are backing up
  LOCAL_BUDIR=${BU_LOCATION}/${SERVER}_${BUDIR//\//_}/$DATE
  LOG_DIR=${LOG_LOCATION}/${SERVER}_${BUDIR//\//_}/$DATE


  findRecentBackup ${SERVER}_${BUDIR//\//_}
  LINK=""
  if [ ${#RECENT} -gt 0 ] 
  then
   echo "LINKING TO RECENT BACKUP: $RECENT"
   LINK=${LINK_OPTION}${BU_LOCATION}/${SERVER}_${BUDIR//\//_}/$RECENT 
  fi
  
  # make the backup dir
  mkdir -p $LOCAL_BUDIR
  BU_CMD="rsync -e ssh -avzi ${LINK} ${EXCLUDE} --delete --delete-excluded root@${SERVER}:$BUDIR $LOCAL_BUDIR"

  mkdir -p $LOG_DIR
  
  echo $BU_CMD
  $BU_CMD > $LOG_DIR/backup.log 2> $LOG_DIR/backup.err

  # check return value of rsync
  if [ $? -ne 0 ]
  then 
    # something wrong happened with rsync
    echo 'ERROR from rync, not rotating backups'
    return
  fi

  # remove old 'current' link and update it
  rm -f ${CURRENTS}/${SERVER}_${BUDIR//\//_}
  ln -s ${LOCAL_BUDIR} ${CURRENTS}/${SERVER}_${BUDIR//\//_}
  
  # roll over backups
  rollover ${BU_LOCATION}/${SERVER}_${BUDIR//\//_} $KEEP
  # roll over log files
  rollover ${LOG_LOCATION}/${SERVER}_${BUDIR//\//_} $KEEP
}

#
# findRecentBackup SERVER
# 
# for a particular server returns the directory of the most
# recent backup
#
findRecentBackup() {
  DIR=$1
  CANDIDATE=$(ls ${BU_LOCATION}/$DIR | sort | tail -1)
  RECENT=""
  if [ -d ${BU_LOCATION}/$DIR/$CANDIDATE ] 
  then
    RECENT=$CANDIDATE
  fi
}

#
# rollover DIR KEEP
# 
# in the directory, DIR, only retain KEEP most recent backups
# This depends on the directories being named with a timestamp of course
#

rollover() {
  DIR=$1
  KEEP=$2
  NUM=$(ls $DIR | wc |awk '{print $1}')
  REMOVE=0
  if [ $NUM -gt $KEEP ]
  then
    REMOVE=$(($NUM - $KEEP))
  fi
  echo "Removing $REMOVE old directories from $DIR"
  for d in $(ls $DIR|sort |head -$REMOVE) 
  do
    rm -rf $DIR/$d
  done
}

backupServer $1

