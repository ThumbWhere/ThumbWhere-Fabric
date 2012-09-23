#!/bin/bash
# Proper header for a Bash script.

RUNNING="`/home/tw-mysqld/mysqld/bin/mysqladmin --user=root --password=new-password --socket=/home/tw-mysqld/mysqld.sock status  2> /dev/null`"
echo "$RUNNING"

while [[ $RUNNING != *Uptime* ]]
do
	sleep 1
	RUNNING="`/home/tw-mysqld/mysqld/bin/mysqladmin --user=root --password=new-password --socket=/home/tw-mysqld/mysqld.sock status  2> /dev/null`"
	echo "$RUNNING"
done
