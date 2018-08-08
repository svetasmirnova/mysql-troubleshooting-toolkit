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

	COMMAND="all"

	MYSQL_COMMAND="mysql -h$MYSQL_HOST -S$MYSQL_SOCKET"
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
					if [ $2 -eq 0 ] 2>/dev/null ; then
						CREATE=0
					else
						CREATE=1
					fi
					#shift
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
					if [ $2 -eq 0 ] 2>/dev/null ; then
						FORCE=0
					else
						FORCE=1
					fi
					#shift
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
			prepare)
				COMMAND="prepare"
				;;
			preprocess)
				COMMAND="preprocess"
				;;
			graph)
				COMMAND="graph"
				;;
			all)
				COMMAND="all"
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

	Command: $COMMAND
	"
}

# checks if source directory exists
check_source()
{
	if [ ! -d "$SOURCE" ]; then
		error "Source directory: $SOURCE does not exist"
	fi
}

# checks if destination directory exists, creates if needed
check_destination()
{
	if [ ! -d "$DESTINATION" ]; then
		if [ $CREATE -eq 1 ]; then
			mkdir -p "$DESTINATION"
		else
			error "Destination directory: $DESTINATION does not exist. Use options --create to automatically create it."
		fi
	else
		if [ "$(ls -A $DESTINATION)" ]; then
			if  ! [ $FORCE -eq 1 ]; then
				error "Destination directory: $DESTINATION is not empty. Use option --force to overwrtite."
			fi
		fi
	fi
}

# checks if directory for temporary files exists, creates if needed
check_tmpdir()
{
	if [ ! -d "$TMPDIR" ]; then
		if [ $CREATE -eq 1 ]; then
			mkdir -p "$TMPDIR"
		else
			error "Directory for temporary files: $TMPDIR does not exist. Use options --create to automatically create it."
		fi
	else
		if [ "$(ls -A $TMPDIR)" ]; then
			if [ $FORCE -eq 0 ]; then
				echo "Directory for temporary files: $DESTINATION is not empty. Files maybe overwritten. Hope this is OK. If not interrupt in 10 seconds"
				sleep 10
				echo "Starting job..."
			else
				echo "Directory for temporary files: $DESTINATION is not empty. Files maybe overwritten. Hope this is OK."
			fi
		fi
	fi
}

# prepares data for further processing
prepare_data()
{
	for i in `find "$SOURCE" -name \*iostat`; do 
		ts=`echo ${i##*/} | sed 's/-iostat//'`
		cat "$i" | sed '/Linux/d' | sed '/Device/d' | sed '/^$/d' | sed 's/ \{1,\}/,/g' | sed "s/^/$ts,/" > "$TMPDIR/${i##*/}" 
	done
}

# creates MySQL connection command
create_mysql_command()
{
	if [ -z $MYSQL_PASSWORD ]; then
		MYSQL_COMMAND="mysql -h$MYSQL_HOST -P$MYSQL_PORT -S$MYSQL_SOCKET -u$MYSQL_USER"
	else
		MYSQL_COMMAND="mysql -h$MYSQL_HOST -P$MYSQL_PORT -S$MYSQL_SOCKET -u$MYSQL_USER -p$MYSQL_PASSWORD"
	fi
}

# checks MySQL connection
check_mysql_connection()
{
	$MYSQL_COMMAND -e "SELECT 1" >/dev/null 2>&1
	if ! [ $? -eq 0 ]; then
		error "Cannot access to MySQL with options: mysql -h$MYSQL_HOST -P$MYSQL_PORT -S$MYSQL_SOCKET -u$MYSQL_USER"
	fi
}

# checks if MySQL database exists, creates if needed
check_db()
{
	$MYSQL_COMMAND $MYSQL_DB -e "show tables" >/dev/null 2>&1
	if ! [ $? -eq 0 ]; then
		if [ $CREATE -eq 1 ]; then
			$MYSQL_COMMAND -e "create database $MYSQL_DB"
			if ! [ $? -eq 0 ]; then
				error "$MYSQL_COMMAND failed with error, cannot continue"
			fi
		else
			error "Database $MYSQL_DB does not exist or cannot be accessed. Use option --create to create it automatically"
		fi
	fi
	num_tables=`$MYSQL_COMMAND -e "select count(*) from information_schema.tables where table_schema='$MYSQL_DB'" -s --skip-column-names`
	if ! [ $num_tables -eq 0 ]; then
		if [ $FORCE -eq 0 ]; then
			error "Database is not empty. Use option --force to re-create table iostat and stored procedure update_time"
		fi
	fi
}

# creates necessary table[s] and routine[s]
prepare_db()
{
	$MYSQL_COMMAND $MYSQL_DB -e "create table if not exists iostat(id int not null auto_increment, ts datetime, device varchar(32), rrqm_s decimal (10,2), wrqm_s decimal(10,2), r_s decimal(10,2), w_s decimal(10,2), rkb_s decimal(10,2), wkb_s decimal(10,2), avgrq_sz decimal (10,2), avgqu_sz decimal(10,2), await decimal(10,2), r_await decimal(10,2), w_await decimal(10,2), svctm decimal(10,2), util decimal(10,2), primary key(id)) engine=innodb;"
	if ! [ $? -eq 0 ]; then
		error "Cannot create table iostat"
	fi
	$MYSQL_COMMAND $MYSQL_DB -e "drop procedure if exists update_time"
	$MYSQL_COMMAND $MYSQL_DB  --delimiter="//" -e "create procedure update_time(disks int) begin DECLARE done INT DEFAULT FALSE; declare ts_read datetime; declare c cursor for select distinct ts from iostat; DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;  open c;  update_loop: loop  fetch c into ts_read;  if done then  leave update_loop; end if;  set @sec = 1; repeat set @stmt= concat('update iostat set ts = addtime(ts, ', @sec, ') where ts = \'', ts_read, '\' limit ', disks); prepare stmt from @stmt; execute stmt; set @sec = @sec + 1; until @sec > 30 end repeat; end loop; close c; end"
	if ! [ $? -eq 0 ]; then
		error "Cannot create procedure update_time"
	fi
	$MYSQL_COMMAND $MYSQL_DB -e "truncate table iostat"
	if ! [ $? -eq 0 ]; then
		error "Cannot truncate table iostat"
	fi
}

# copies required files to datadir for LOAD DATA INFILE
# TODO: support LOAD DATA LOCAL INFILE, avoid copy
copy_to_datadir()
{
	datadir=`$MYSQL_COMMAND $MYSQL_DB -s --skip-column-names -e "select @@datadir"`
	for i in `find $TMPDIR/* -name \*iostat\*`; do
		cp "$i" "$datadir/$MYSQL_DB"
	done
}

# loads data into iostat table
load_data()
{
	for i in `find $TMPDIR/* -name \*iostat\*`; do
		bi=`basename $i`
		$MYSQL_COMMAND $MYSQL_DB -e "load data infile '$bi' into table iostat fields terminated by ',' (ts, device, rrqm_s, wrqm_s, r_s, w_s, rkb_s, wkb_s, avgrq_sz, avgqu_sz, await, r_await, w_await, svctm, util);"
		if ! [ $? -eq 0 ]; then
			error "Cannot load data in file: $bi"
		fi
	done
}

# preprocesses data in the database for passing to R script
preprocess_data()
{
	datadir=`$MYSQL_COMMAND $MYSQL_DB -s --skip-column-names -e "select @@datadir"`
	num_disks=`$MYSQL_COMMAND $MYSQL_DB -s -N -e "select count(distinct device) from iostat"`
	$MYSQL_COMMAND $MYSQL_DB -e "call update_time($num_disks)"
	for i in `$MYSQL_COMMAND $MYSQL_DB -s -N -e "select distinct device from iostat"`; do
		$MYSQL_COMMAND $MYSQL_DB -e "select * into outfile '$i.disk' FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' from iostat where device='$i' order by ts, id"
		mv "$datadir/$MYSQL_DB/$i.disk" "$TMPDIR"
	done
	$MYSQL_COMMAND $MYSQL_DB -e "select * into outfile 'all_disks' FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' from iostat order by ts, id"
	mv "$datadir/$MYSQL_DB/all_disks" "$TMPDIR"
}

# creates per-disk graphs
create_per_disk_graphs()
{
	for i in `ls $TMPDIR/*.disk`; do
		./iostat_disk.R `basename $i` "$TMPDIR" "$DESTINATION"
	done
}

# creates per-metric graphs for all disks
create_per_metric_graphs()
{
	./iostat_metrics.R all_disks "$TMPDIR" "$DESTINATION"
}

# executes commands
execute_prepare()
{
	echo "Preparing data for preprocessing..."
	prepare_data
}

execute_preprocess()
{
	echo "Preprocessing data..."
	create_mysql_command
	check_mysql_connection
	check_db
	prepare_db
	copy_to_datadir
	load_data
	preprocess_data
}

execute_graph()
{
	echo "Creating graphs..."
	create_per_disk_graphs
	create_per_metric_graphs
}

initialize
parse $@
check
print_options

check_source
check_destination
check_tmpdir

case $COMMAND in
	prepare)
		execute_prepare
		;;
	preprocess)
		execute_preprocess
		;;
	graph)
		execute_graph
		;;
	all)
		execute_prepare
		execute_preprocess
		execute_graph
		;;
	*)
		error "Unknown command"
esac

#send data to R script for creating graphs - command graph
#output - destination

#default command - all

exit 0
