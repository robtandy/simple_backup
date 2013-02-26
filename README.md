Simple Backup 
=============

Motivation
----------
These shell scripts extend rsync as a backup tool and add simple features like automatic rollovers.  Rsync combined with its --link-dest= option is a powerful way to backup remote linux systems.  The --link-dest= option lets us specify a previous backup to hard link against.  That is, if we find the same file, unchanged, in the current backup, just make a hardlink to the previous backup.  Google for the difference between hard and soft links in linux for any clarificaiton here.

Usage
-----
1. Generate (if you haven't yet) and copy root's ssh public key to the machines you want to backup using (`ssh-keygen`) and `ssh-copy-id`

2. Copy `example.config.example` in the `configs` directory and rename it to something ending in `.config`.  Edit the three options there as appropriate (machine IP, what directory to backup and what to skip)

3. Test.  Run ./bin/backup_all.sh to capture one backup.  I usually setup the BACKUP_DIR in the previous step to be `/tmp/` to test that everything works ok before changing it to `/` and scheduling a cron job.  

4. Schedule using cron.  Something like this should work.
    5 0 * * * /simple_backup/bin/backup_all.sh
if you want to run at 12:05 AM and you've checked this repo to /simple_backup/

Where is my stuff?
------------------
The scripts figure out what directory they are in and will backup to the `servers` and write logs into the `logs` directory along side `bin` where the scripts live. The `currents` directory will point to the most recent backup for each server.  



