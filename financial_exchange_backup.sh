#!/bin/bash

FILE_PREFIX="db_backup_"
DB_NAME="financial_exchange"
BACKUP_DIR="backups"
DAILY_DIR="$BACKUP_DIR/daily"
WEEKLY_DIR="$BACKUP_DIR/weekly"
BACKUP_FILE="$BACKUP_DIR/$FILE_PREFIX$(date +'%Y-%m-%d_%H:%M').tar"

create_backup_dirs() {
    local DIRS=("$BACKUP_DIR" "$DAILY_DIR" "$WEEKLY_DIR")

    for dir in "${DIRS[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -m 700 -p "$dir"
        fi
    done
}

backup_database() {
    pg_dump -d $DB_NAME -Ft | gzip > $BACKUP_FILE.gz
}

retain_daily_backup() {
    if ! find "$DAILY_DIR" -type f -name "$FILE_PREFIX$(date +'%Y-%m-%d')*.tar.gz" -print -quit | grep -q .; then
        cp -p $BACKUP_FILE.gz $DAILY_DIR
    fi
}

delete_old_daily_backups() {
    find $DAILY_DIR -type f -mtime +2 -delete
}

retain_weekly_backup() {
    if ! find "$WEEKLY_DIR" -type f -newermt "last sunday" -print -quit | grep -q .; then
        cp -p $BACKUP_FILE.gz $WEEKLY_DIR
    fi
}

retain_latest_backups() {
    ls -dt $BACKUP_DIR/*| grep $FILE_PREFIX | tail -n +6 | xargs rm -f
}

create_backup_dirs
backup_database
retain_daily_backup
delete_old_daily_backups
retain_weekly_backup
retain_latest_backups
