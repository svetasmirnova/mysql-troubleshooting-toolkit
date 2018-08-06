#!/bin/bash

# Processes iostat output, sends result to R script to create graphs

# Print usage information
usage()
{
	echo "$VERSION"
	echo "
	`basename $0` reads files with iostat output, then sends them to
		- sed to remove headers
		- MySQL to prepare data
		- R to create graphs

	Usage: `basename $0` --source=DIR_WITH_IOSTAT --destination=OUTPUT_DIR [OPTIONS] [command]

	Options:

		-s --source			directory, containing iostat outuput
		-d --destination	directory where to put graphs
		-t --tmpdir			directory to hold pre-proceed files (default same as --destination)

		-h --mysql-host		MySQL host
		-P --mysql-port		MySQL port
		-S --mysql-socket	MySQL socket
		-u --mysql-user		MySQL user
		-p --mysql-password	MySQL password
		-db --mysql-db		MySQL database where to create temporary tables and procedures
		
		-c --create			create destination directory and MySQL database if not exist
		-f --force			overwrite files in destination directory if exist
							and truncate MySQL tables if not empty

		-h --help			print this help

	Available commands:
		prepare				prepares iostat data to be loaded for pre-processing
		preprocess			prepares data for R script
		graph				creates graphs
		all					performs complete operation
	"
}

# error exit
error()
{
	printf "$@\n" >&2
	exit $E_CDERROR
}

# sets default values
initialize()
{
	VERSION="`basename $0` v0.1 (August 7 2018)"
	E_CDERROR=65
	
	SOURCE=""
	DESTINATION=""
	TMPDIR=""
	
	MYSQL_HOST="localhost"
	MYSQL_PORT=3306
	MYSQL_SOCKET="/tmp/mysql.sock"
	MYSQL_USER=""
	MYSQL_PASSWORD=""
	MYSQL_DB=""

	CREATE=0
	FORCE=0
}

# parses arguments/sets values to defaults
parse()
{
	while :; do
		case $1 in
			\?|--help)
				usage
				exit 0
				;;
			-s|--source)
				if [ "$2" ]; then
					SOURCE="$2"
					shift
				else
					error "Option --source requires an argument"
				fi
				;;
			--source=?*)
				SOURCE=${1#*=}
				;;
			-d|--destination)
				if [ "$2" ]; then
					DESTINATION="$2"
					shift
				else
					error "Option --destination requires an argument"
				fi
				;;
			--destination=?*)
				DESTINATION=${1#*=}
				;;
			-t|--tmpdir)
				if [ "$2" ]; then
					TMPDIR="$2"
					shift
				else
					error "Option --tmpdir requires an argument"
				fi
				;;
			--tmpdir=?*)
				TMPDIR=${1#*=}
				;;
			-h|--mysql-host)
				if [ "$2" ]; then
					MYSQL_HOST="$2"
					shift
				else
					error "Option --mysql-host requires an argument"
				fi
				;;
			--mysql-host=?*)
				MYSQL_HOST=${1#*=}
				;;
			-P|--mysql-port)
				if [ "$2" ]; then
					MYSQL_PORT="$2"
					shift
				else
					error "Option --mysql-port requires an argument"
				fi
				;;
			--mysql-port=?*)
				MYSQL_PORT=${1#*=}
				;;
			-S|--mysql-socket)
				if [ "$2" ]; then
					MYSQL_SOCKET="$2"
					shift
				else
					error "Option --mysql-socket requires an argument"
				fi
				;;
			--mysql-socket=?*)
				MYSQL_SOCKET=${1#*=}
				;;
			-u|--mysql-user)
				if [ "$2" ]; then
					MYSQL_USER="$2"
					shift
				else
					error "Option --mysql-user requires an argument"
				fi
				;;
			--mysql-user=?*)
				MYSQL_USER=${1#*=}
				;;
			-p)
				MYSQL_PASSWORD=${1#*}
				;;
			--mysql-password=?*)
				MYSQL_PASSWORD=${1#*=}
				;;
			-db|--mysql-db)
				if [ "$2" ]; then
					MYSQL_DB="$2"
					shift
				else
					error "Option --mysql-db requires an argument"
				fi
				;;
			--mysql-db=?*)
				MYSQL_DB=${1#*=}
				;;
			-c|--create)
				if [ "$2" ]; then
					if [ $2 -eq 1 -o $2 -eq 0 ] 2>/dev/null ; then
						CREATE="$2"
						shift
					else
						error "Option --create can be only 1 or 0"
					fi
				else
					CREATE=1
				fi
				;;
			--create=?*)
				CREATE=${1#*=}
				if ! [ $CREATE -eq 1 -o $CREATE -eq 0 ] 2>/dev/null ; then
					error "Option --create can be only 1 or 0"
				fi
				;;
			-f|--force)
				if [ "$2" ]; then
					if [ $2 -eq 1 -o $2 -eq 0 ] 2>/dev/null ; then
						FORCE="$2"
						shift
					else
						error "Option --force can be only 1 or 0"
					fi
				else
					FORCE=1
				fi
				;;
			--force=?*)
				FORCE=${1#*=}
				if ! [ $FORCE -eq 1 -o $FORCE -eq 0 ] 2>/dev/null ; then
					error "Option --force can be only 1 or 0"
				fi
				;;
			-?*)
				error "Unknown option $1"
				;;
			*)
				break
				;;
		esac

		shift
	done
}

# checks if all required arguments set
check()
{
	if [ -z $SOURCE ]; then
		error "Option --source must be set"
	fi

	if [ -z $DESTINATION ]; then
		error "Option --destination must be set"
	fi

	if [ -z $MYSQL_DB ]; then
		error "Option --mysql-db must be set"
	fi

	if ! [[ $MYSQL_PORT =~ ^[1-9][0-9]*$ ]]; then
		error "Option --mysql-port must be a number"
	fi

	if [ -z $TMPDIR ]; then
		TMPDIR="$DESTINATION"
	fi
}

# prints options
print_options()
{
	echo "`basename $0` started with options:
	
	--source=$SOURCE
	--destination=$DESTINATION
	--tmpdir=$TMPDIR

	--mysql-host=$MYSQL_HOST
	--mysql-port=$MYSQL_PORT
	--mysql-socket=$MYSQL_SOCKET
	--mysql-user=$MYSQL_USER
	--mysql-db=$MYSQL_DB

	--create=$CREATE
	--force=$FORCE
	"
}

initialize
parse $@
check
print_options

#check source; if not exists - fail
#check destination, create if needed; if not empty and no --force - fail
#check tmpdir, create if needed
#process input data - command prepare
#output - tmpdir

#check if can connect to MySQL
#check if MySQL db exists
## if create - create
## if has table/SP and no --force - fail
## otherwise create table/SP
#prepare data for R script - command preprocess
#output - tmpdir

#send data to R script for creating graphs - command graph
#output - destination

#default command - all

exit 0
