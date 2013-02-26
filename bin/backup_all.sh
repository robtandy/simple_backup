#!/bin/bash

#Directory of this script
DIR=$(cd $(dirname "$0"); pwd)

# root directory of backup script and tree
BACKUP_DIR=$DIR/../

RUN_DIR=$BACKUP_DIR/var/

if [ ! -d $RUN_DIR ]
then
    mkdir -p $RUN_DIR
fi

RUN_FILE=$RUN_DIR/backup_is_running

# first check if a stamp file indicating we are already running exists
# if so, abort
if [ -a $RUN_FILE ]
then
    echo ""
    echo "ERROR: backup_all is already running as $RUN_FILE exists"
    echo ""
    echo "if its not running remove $RUN_FILE before running this script"
    exit 1
    echo ""
fi

cd $BACKUP_DIR

touch $RUN_FILE

for s in $(ls configs/*config)
do
    ./bin/do_backup.sh $s
done

# clean up

rm -f $RUN_FILE


