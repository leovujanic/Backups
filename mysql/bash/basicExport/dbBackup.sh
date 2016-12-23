#!/usr/bin/env bash


# Database Username
DBUSER=

# Database password - leave empty if there is no password
DBPASS=""

# databases to be exported use "*" if you want backup all DB-s
# for specific databases use "db1, db2,db3"
DATABASES="*"

# Destination directory
#DUMP_DESTINATION="/Users/leonardvujanic/mysqlDump/dumps"
DUMP_DESTINATION=


# colors
RED="\e[31m"
NC="\e[0m"
GREEN="\e[32m"
BLUE="\e[34m"

# usage print out
usage() {
printf "${GREEN} Basic mysql backup ${NC}\n"
cat<<'EOF'
This script exports databases via mysql dump.
It will create folders in specified output folder in format YEAR / MONTH / and place output file in it.

OPTIONS:
   -h      Show this message
   -u      Database username - REQUIRED
   -p      Database password - default empty
   -o      Output directory  - must be specified as full path
   -d     Databases list.   - dafault "*" --all databases
           For specific database use comaseparated values like "db1, db2,db3"
EOF
}


if [ -f "config.sh" ];
    then
        source config.sh
    fi

while getopts ":u:p:o:d:h" opt; do
    case $opt in
        h)
            usage
            exit 1;
            ;;
        u)
            DBUSER=$OPTARG
            ;;
        p)
            DBPASS=$OPTARG
            ;;
        o)
            DUMP_DESTINATION=$OPTARG
            ;;
        d)
            DATABASES=$OPTARG
            ;;
        \?) echo "Invalid option -$OPTARG. Use -h option for help." >&2
            exit 0;
            ;;
    esac
done


if [[ -z $DBUSER ]] || [[ -z $DUMP_DESTINATION ]]
then
     usage
     exit 1
fi

printf "Starting mysql export in '%s' BASH version\n" $BASH_VERSION

printf "Checking destination directory is absolute path '%s' : " $DUMP_DESTINATION;

# print OK status
echoOk() {
    printf "[ ${GREEN} OK ${NC} ]\n"
}

# print NOK status
echoNok() {
    printf "[ ${RED} NOK ${NC} ]\n"
}

if [[ $DUMP_DESTINATION == /* ]]
then
    echoOk
else
    echoNok
    printf "${RED}ERROR: Destination directory must be specified as absolute path $NC\n"
    exit 1;
fi

# Remove trailing slashes if they exists and append one
DUMP_DESTINATION="$(echo $DUMP_DESTINATION | sed 's:/*$::')/"

printf "Checking destination directory '$DUMP_DESTINATION' : ";

# Validate destination directory
if [ -d "$DUMP_DESTINATION" ]
then
    echoOk
else
    echoNok
    echo "Destination directory does not exists"
    echo "Stopping mysql export"
    exit 1
fi

DIRNAME="${DUMP_DESTINATION}`date +%Y/%m`/"

echo "Creating backup directory:  ${DIRNAME}"

mkdir -p ${DIRNAME}

# backup one db
buCommand() {
    local fileName="$2$1_`date +%Y-%m-%d-%H-%I-%S`.dump"

    if [[ -z $DBPASS ]]
    then
        mysqldump --routines -u "$DBUSER" --databases "$1" > "$fileName"
    else
        mysqldump --routines -u "$DBUSER" -p"$DBPASS" --databases "$1" > "$fileName"
    fi
}

# backup all dbs
buAllDb() {
    local fileName="$1all_databases_`date +%Y-%m-%d-%H-%I-%S`.dump"
    if [[ -z $DBPASS ]]
    then
        mysqldump --routines --all-databases -u $DBUSER  > "$fileName"
    else
        mysqldump --routines --all-databases -u $DBUSER -p$DBPASS > "$fileName"
    fi
}

if [ "$DATABASES" == '*' ]
then
    printf "Creating backup for all databases "
    ERROR=$(buAllDb "$DIRNAME" 2>&1 >/dev/null)

    if [ $? -eq 0 ]; then
        echoOk
    else
        echoNok
        echo "Captured error: "
        echo "$ERROR"
    fi

else
    IFS=',' read -r -a DBARRAY <<< "$DATABASES"

    for db in "${DBARRAY[@]}"
    do
        dbName="$(echo -e "${db}" | tr -d '[:space:]')"

        printf "Creating backup for database: %s " $dbName

        ERROR=$(buCommand "$dbName" "$DIRNAME" 2>&1 >/dev/null)

        if [ $? -eq 0 ]; then
            echoOk
        else
            echoNok
            echo "Captured error: "
            echo "$ERROR"
        fi
    done
fi
