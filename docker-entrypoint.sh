#!/bin/bash
set -e

# TODO read this from the MySQL config?
DATADIR='/var/lib/mysql'

if [ "${1:0:1}" == '-' -o -z "${1}" ]; then
	set -- /usr/sbin/mysqld "$@"
fi

# IP Address for MySQL server, first defined out of
# * MYSQL_PORT_3306_TCP_ADDR - when using docker link
# * MYSQL_HOST - shorthand
# * 172.17.42.1 - default docker bridge
CLIENT_HOST="${MYSQL_PORT_3306_TCP_ADDR:-${MYSQL_HOST:-172.17.42.1}}"
# Same again for the IP port
CLIENT_PORT="${MYSQL_PORT_3306_TCP_PORT:-${MYSQL_PORT:-3306}}"
# Default user is root, overridable with MYSQL_USER
CLIENT_USER="${MYSQL_USER:-root}"
# Default password is the first defined out of;
# MYSQL_ENV_MYSQL_ROOT_PASSWORD - when using docker link
# MYSQL_ROOT_PASSWORD - shorthand
# MYSQL_PASSWORD - even shorterhand
CLIENT_PASS="${MYSQL_ENV_MYSQL_ROOT_PASSWORD:-${MYSQL_PASSWORD:-${MYSQL_ROOT_PASSWORD}}}"
# prefix the password with the client cli parameter
if [ ! -z "${CLIENT_PASS}" ]; then
    CLIENT_PASS="-p${CLIENT_PASS}"
fi
# put all it all together
CLIENT_CMD="/usr/bin/mysql -h${CLIENT_HOST} -P${CLIENT_PORT} -u${CLIENT_USER}${CLIENT_PASS}"
# if you pass prompt as the command then start a mysql client
if [ "${1}" == "prompt" ]; then
	set -- ${CLIENT_CMD} ${MYSQL_DATABASE}
fi
# if the command is not full pathed (e.g. starts with a forward slash) then
# assume it is SQL
if [ "${1:0:1}" != '/' ]; then
	set -- ${CLIENT_CMD} -e "$@" ${MYSQL_DATABASE}
fi

if [ ! -d "$DATADIR/mysql" -a "${1%_safe}" = 'mysqld' ]; then
	if [ -z "$MYSQL_ROOT_PASSWORD" -a -z "$MYSQL_ALLOW_EMPTY_PASSWORD" ]; then
		echo >&2 'error: database is uninitialized and MYSQL_ROOT_PASSWORD not set'
		echo >&2 '  Did you forget to add -e MYSQL_ROOT_PASSWORD=... ?'
		exit 1
	fi
	
	echo 'Running mysql_install_db ...'
	mysql_install_db
	echo 'Finished mysql_install_db'
	
	# These statements _must_ be on individual lines, and _must_ end with
	# semicolons (no line breaks or comments are permitted).
	# TODO proper SQL escaping on ALL the things D:
	
	tempSqlFile='/tmp/mysql-first-time.sql'
	cat > "$tempSqlFile" <<-EOSQL
		DELETE FROM mysql.user ;
		CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
		GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
		DROP DATABASE IF EXISTS test ;
	EOSQL
	
	if [ "$MYSQL_DATABASE" ]; then
		echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` ;" >> "$tempSqlFile"
	fi
	
	if [ "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]; then
		echo "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' ;" >> "$tempSqlFile"
		
		if [ "$MYSQL_DATABASE" ]; then
			echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%' ;" >> "$tempSqlFile"
		fi
	fi
	
	echo 'FLUSH PRIVILEGES ;' >> "$tempSqlFile"
	
	set -- "$@" --init-file="$tempSqlFile"
fi

chown -R mysql:mysql "$DATADIR"
exec "$@"
