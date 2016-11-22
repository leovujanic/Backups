#!/usr/bin/env bash

# Database Username
declare -r DBUSER="root"

# Database password - leave empty if there is no password
declare -r DBPASS=""

# databases to be exported use "*" if you want backup all DB-s
declare -r DATABASES="*"

# Destination directory
DUMP_DESTINATION="/Users/leonardvujanic/mysqlDump/dumps"
