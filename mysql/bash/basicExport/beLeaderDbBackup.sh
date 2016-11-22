#!/usr/bin/env bash

# Load config variables
source config.sh

# colors
RED="\e[31m"
NC="\e[0m"
GREEN="\e[32m"
BLUE="\e[34m"

echo "Starting mysql export...";

echo -n "Checking destination directory is absolute path '$DUMP_DESTINATION' : ";

if [[ $DUMP_DESTINATION == /* ]]
then
    echo -e "[ $GREEN OK $NC ]"
else
    echo -e "[ $RED NOK $NC ]"
    echo -e "$RED ERROR: Destination directory must be specified as absolute path $NC"
    exit 1;
fi

# Remove trailing slashes if they exists and append one
DUMP_DESTINATION="$(echo $DUMP_DESTINATION | sed 's:/*$::')/"

echo -n "Checking destination directory '$DUMP_DESTINATION' : ";

# Validate destination directory
if [ -d "$DUMP_DESTINATION" ]
then
    echo -e "[ $GREEN OK $NC ]"
else
    echo -e "[ $RED NOK $NC ]"
    echo "Destination directory does not exists"
    echo "Stopping mysql export"
    exit 1
fi

DIRNAME="${DUMP_DESTINATION}`date +%Y/%m`/"

echo "Creating backup directory:  ${DIRNAME}"

mkdir -p ${DIRNAME}

# backup one db
buCommand() {
    local fileName="$2$1_`date +%Y-%m-%d`.dump"

    if [[ -z $DBPASS ]]
    then
        mysqldump --routines -u "$DBUSER" --databases "$1" > "$fileName"
    else
        mysqldump --routines -u "$DBUSER" -p"$DBPASS" --databases "$1" > "$fileName"
    fi
}

# backup all dbs
buAllDb() {
    local fileName="$1all_databases_`date +%Y-%m-%d`.dump"
    if [[ -z $DBPASS ]]
    then
        mysqldump --routines --all-databases -u $DBUSER  > "$fileName"
    else
        mysqldump --routines --all-databases -u $DBUSER -p$DBPASS > "$fileName"
    fi
}



if [ "$DATABASES" == '*' ]
then
    echo -n "Creating backup for all databases "
    ERROR=$(buAllDb "$DIRNAME" 2>&1 >/dev/null)

    if [ $? -eq 0 ]; then
        echo -e "[ $GREEN OK $NC ]"
    else
        echo -e "[ $RED NOK $NC ]"
        echo "Captured error: "
        echo "$ERROR"
    fi

else
    IFS=',' read -r -a DBARRAY <<< "$DATABASES"

    for db in "${DBARRAY[@]}"
    do
        dbName="$(echo -e "${db}" | tr -d '[:space:]')"

        echo -n "Creating backup for database: $dbName "

        ERROR=$(buCommand "$dbName" "$DIRNAME" 2>&1 >/dev/null)

        if [ $? -eq 0 ]; then
            echo -e "[ $GREEN OK $NC ]"
        else
            echo -e "[ $RED NOK $NC ]"
            echo "Captured error: "
            echo "$ERROR"
        fi
    done
fi
