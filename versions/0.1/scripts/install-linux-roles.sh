#!/bin/bash
# Proper header for a Bash script.

###############################################################################
#
# This will setup ThumbWhere Fabric node on a Linux Box
#
# Although this script can be run manually, in will generally
# be executed as part of an automated install if thumbwhere is 
# configured with credentials of the target host that can perform 
# tasks as root or use sudo.
#
# Bootstrapping
# -------------
#
# This script can be downloaded using the following command
# 
# For systems with wget, run this line.
#
# rm install-linux-roles.sh; wget -nc https://raw.github.com/ThumbWhere/ThumbWhere-Fabric/master/versions/0.1/scripts/install-linux-roles.sh; chmod +x install-linux-roles.sh ; sudo -E bash ./install-linux-roles.sh
#
# For systems with curl, run this line
#
# curl -O https://raw.github.com/ThumbWhere/ThumbWhere-Fabric/master/versions/0.1/scripts/install-linux-roles.sh; chmod +x install-linux-roles.sh; sudo -E bash ./install-linux-roles.sh
# 
#

# We want the script to fail on any errors... so..
set -e

###############################################################################
#
# Config variables ; Each one can contain the following keywords "download,compile,install,configure,enable"
# If enable is not part of the string, then the service is deemed to be 'disabled'
#

#if [ "$IRCD_ROLE" = "" ] 
#then
#	IRCD_ROLE=download,compile,install,configure,enable
#fi
#
#if [ "$REDIS_ROLE" = "" ] 
#then
#	REDIS_ROLE=download,compile,install,configure,enable
#fi
#
#if [ "$NODEJS_ROLE" = "" ] 
#then
#	NODEJS_ROLE=download,compile,install,configure,enable
#fi
#
#if [ "$VARNISH_ROLE" = "" ] 
#then
#	VARNISH_ROLE=disable
#fi
#
#if [ "$NGINX_ROLE" = "" ] 
#then
#	NGINX_ROLE=download,compile,install,configure,enable
#fi
#
#if [ "$HTTPD_ROLE" = "" ] 
#then
#	HTTPD_ROLE=download,compile,install,configure,enable
#fi
##
#if [ "$FTPD_ROLE" = "" ] 
#then
#	FTPD_ROLE=download,compile,install,configure,enable
#fi
#
#if [ "$MYSQLD_ROLE" = "" ] 
#then
#	MYSQLD_ROLE=download,compile,install,configure,enable
#fi

if [ "$PHP_ROLE" = "" ] 
then
	PHP_ROLE=download,compile,install,configure,enable
fi


IRCDURL=http://downloads.sourceforge.net/project/inspircd/InspIRCd-2.0/2.0.2/InspIRCd-2.0.2.tar.bz2
REDISURL=http://redis.googlecode.com/files/redis-2.4.6.tar.gz
NODEJSURL=http://nodejs.org/dist/v0.9.1/node-v0.9.1.tar.gz
VARNISHURL=http://repo.varnish-cache.org/source/varnish-3.0.2.tar.gz
NGINXURL=http://nginx.org/download/nginx-1.0.11.tar.gz
HTTPDURL=http://apache.mirror.aussiehq.net.au/httpd/httpd-2.2.22.tar.gz
FTPDURL=ftp://ftp.proftpd.org/distrib/source/proftpd-1.3.4a.tar.gz
# See: http://dev.mysql.com/get/Downloads/MySQL-5.5/mysql-5.5.27.tar.gz/from/http://cdn.mysql.com/
MYSQLDURL=http://cdn.mysql.com/Downloads/MySQL-5.5/mysql-5.5.27.tar.gz
PHPURL="http://au.php.net/get/php-5.4.7.tar.gz/from/this/mirror --output-file=php-5.4.7.tar.gz"

###############################################################################
#
# Generate some more convenient variables based on our config.
#

DOWNLOADS=~/tw-downloads
HOMEROOT=/home

GROUP=thumbwhere
IRCDUSER=tw-ircd
REDISUSER=tw-redis
NODEJSUSER=tw-nodejs
VARNISHUSER=tw-varnish
NGINXUSER=tw-nginx
HTTPDUSER=tw-httpd
FTPDUSER=tw-ftpd
MYSQLDUSER=tw-mysqld
PHPUSER=tw-php

IRCDFILE=`echo $IRCDURL | rev | cut -d\/ -f1 | rev`
REDISFILE=`echo $REDISURL | rev | cut -d\/ -f1 | rev`
NODEJSFILE=`echo $NODEJSURL | rev | cut -d\/ -f1 | rev`
VARNISHFILE=`echo $VARNISHURL | rev | cut -d\/ -f1 | rev`
NGINXFILE=`echo $NGINXURL | rev | cut -d\/ -f1 | rev`
HTTPDFILE=`echo $HTTPDURL | rev | cut -d\/ -f1 | rev`
FTPDFILE=`echo $FTPDURL | rev | cut -d\/ -f1 | rev`
MYSQLDFILE=`echo $MYSQLDURL | rev | cut -d\/ -f1 | rev`
PHPFILE=`echo $PHPURL | rev | cut -d\= -f1 | rev`

IRCDFOLDER=`echo $IRCDFILE | rev | cut -d\. -f3- | rev`
REDISFOLDER=`echo $REDISFILE | rev | cut -d\. -f3- | rev`
NODEJSFOLDER=`echo $NODEJSFILE | rev | cut -d\. -f3- | rev`
VARNISHFOLDER=`echo $VARNISHFILE | rev | cut -d\. -f3- | rev`
NGINXFOLDER=`echo $NGINXFILE | rev | cut -d\. -f3- | rev`
HTTPDFOLDER=`echo $HTTPDFILE | rev | cut -d\. -f3- | rev`
FTPDFOLDER=`echo $FTPDFILE | rev | cut -d\. -f3- | rev`
MYSQLDFOLDER=`echo $MYSQLDFILE | rev | cut -d\. -f3- | rev`
PHPFOLDER=`echo $PHPFILE | rev | cut -d\. -f3- | rev`

IRCDPROCESS=inspircd
IRCDCONFIG=/etc/inspircd/inspircd.conf
IRCDPID=$HOMEROOT/$IRCDUSER/inspircd.pid

REDISCONFIG=$HOMEROOT/$REDISUSER/redis.conf
REDISLOGS=$HOMEROOT/$REDISUSER
REDISPID=$HOMEROOT/$REDISUSER/redis.pid
REDISPROCESS=redis-server

VARNISHCONFIG=$HOMEROOT/$VARNISHUSER/thumbwhere.vcl
VARNISHPROCESS=varnishd
VARNISHPID=$HOMEROOT/$VARNISHUSER/varnish.pid

NGINXPROCESS=nginx
NGINXROOT=$HOMEROOT/$NGINXUSER/nginx
NGINXCONFIG=$HOMEROOT/$NGINXUSER/nginx/conf/nginx.conf
NGINXPID=$HOMEROOT/$NGINXUSER/nginx/nginx.pid

HTTPDROOT=$HOMEROOT/$HTTPDUSER/apache2
HTTPDCONFIG=$HTTPDROOT/conf/httpd.conf
HTTPDPID=$HOMEROOT/$HTTPDUSER/httpd.pid
HTTPDPROCESS=httpd

FTPDROOT=$HOMEROOT/$FTPDUSER/ftpd
FTPDCONFIG=$FTPDROOT/etc/proftpd.conf
FTPDPID=$FTPDROOT/var/proftpd.pid
FTPDPROCESS=proftpd

PHPROOT=$HOMEROOT/$PHPUSER/php
PHPCONFIG=$PHPROOT/etc/php.conf.test


MYSQLDROOT=$HOMEROOT/$MYSQLDUSER/mysqld
MYSQLDCONFIG=$HOMEROOT/$MYSQLDUSER/.my.cnf
MYSQLDPID=$HOMEROOT/$MYSQLDUSER/mysqld.pid
MYSQLDSOCKET=$HOMEROOT/$MYSQLDUSER/mysqld.sock
MYSQLDPROCESS=mysqld
MYSQLDDATAROOT=$HOMEROOT/$MYSQLDUSER/data
if [ "$MYSQLDPASSWORD" = "" ] 
then
	MYSQLDPASSWORD=new-password
fi

groupadd -f thumbwhere

#
# Some handy constants
#

# Escape code
esc=`echo -en "\033"`

# Set colors
cc_red="${esc}[0;31m"
cc_green="${esc}[0;32m"
cc_yellow="${esc}[0;33m"
cc_blue="${esc}[0;34m"
cc_cyan="${esc}[0;36m"
cc_white="${esc}[1;37m"
cc_purple="${esc}[0;35m"
cc_lgray="${esc}[0;37m"
cc_dgray="${esc}[1;30m"
cc_normal=`echo -en "${esc}[m\017"`

#
# Functions for things we do a lot of..
#


#
# We run this at the beginning of an install to create the user if it does not exist, and if it does, stop the server if it is running.
# We assume that no user == no server.
#

create_user()
{
	p_user=$1
	

	if [ "`id -un ${p_user}`" != "${p_user}" ]
	then
		echo " - Adding user ${p_user}"
		useradd ${p_user} -m -g $GROUP
	fi
}

create_user_and_stop_service()
{
	p_user=$1
	p_process=$2

	create_user ${p_user}

	if killall -0 ${p_process}
	then
		if [ -f /etc/init.d/${p_user}-server ]
		then
			echo " - Stopping service"
			echo "--------- start ----------"
			/etc/init.d/${p_user}-server stop
			echo "---------- end -----------"
		else
			echo " - Killing service (control script not found at /etc/init.d/${p_user}-server)"
			killall -2 ${p_process}
			#for i in `ps ax | grep ${p_process} | grep -v grep | cut -d ' ' -f 1`
			#do
			#	kill -2 $i
			#done
		fi
	fi

}


#
# We run this at the end where we enable the service or disable it if we don't pass in the 'enabled' flag.
#

enable_disable()
{
	p_user=$1
	p_task=$2

	# If we are configured and ready to run..
	if [ -f /etc/init.d/${p_user}-server ]
	then
		if [[ ${p_task} = *enable* ]]
		then
			# If we are enabling...
			echo " - Enabling service."
			if [[ $os = "debian" ]]
			then
				insserv /etc/init.d/${p_user}-server 2> /dev/null
			elif [[ $os = "centos" ]] || [[ $os = "ubuntu" ]]
			then
				chkconfig ${p_user}-server on 2> /dev/null
			else
				ln -fs /etc/init.d/${p_user}-server /etc/rc2.d/S19${p_user}-server 2> /dev/null
			fi
			
			echo " - Starting service."
			echo "--------- start ----------"
			/etc/init.d/${p_user}-server start	
			echo "---------- end -----------"			
		else
			echo " - Disabling service."
		
			# .. we disable..
			if [ $os = "debian" ]
			then
				insserv -r /etc/init.d/${p_user}-server 2> /dev/null
			elif [ $os = "centos" ] || [ $os = "ubuntu" ] 
			then
				chkconfig ${p_user}-server off 2> /dev/null
			else
				rm -r /etc/rc2.d/S19${p_user}-server 2> /dev/null
			fi	
		fi
	else
		echo " - Service is not configured."
		if [[ ${p_task} = *enable* ]]
		then
			echo " - CRITICAL ${cc_red}FAIL${cc_normal} We want the service enabled, but there are no control scripts. Service needs to be configured."
			exit 1
		fi

	fi
}


#
# Install the tools we will need
#

os=""

if [ "`grep centos /proc/version -c`" != "0" ] 
then
	os="centos"
fi

if [ "`grep \"Red Hat\" /proc/version -c`" != "0" ] 
then
	os="centos"
fi

if [ "`grep debian /proc/version -c`" != "0" ] 
then
	os="debian"
fi

if [ "`grep ubuntu /proc/version -c`" != "0" ]
then
	os="ubuntu"
	
	if [ ! -f /sbin/insserv ]
	then
		ln -s /usr/lib/insserv/insserv /sbin/insserv
	fi
	
fi


if [ "$os" = "" ] 
then
	echo "Unable to determine os from `cat /proc/version -c`"
	exit 1
fi

if [ $os = "debian" ] || [ $os = "ubuntu" ]
then
	apt-get -y install wget bzip2 binutils g++ make tcl8.5 curl build-essential openssl libssl-dev libssh-dev pkg-config libpcre3 libpcre3-dev libpcre++0 xsltproc libncurses5-dev cmake bison libxml2-dev libgdbm-dev libpng12-dev libjpeg-dev autoconf libcurl4-gnutls-dev 
elif [ $os = "centos" ]
then
	yum -y install wget bzip2 binutils gcc-c++ make gcc tcl curl openssl pcre gnutls openssh openssl ncurses pcre-devel gnutls-devel openssl-devel ncurses-devel libxslt redhat-lsb cmake bison libxml2-dev libgdbm-dev libpng12-dev libjpeg-dev autoconf libcurl4-gnutls-dev 
fi

#
# Install the source packages...
#

echo "*** ${cc_cyan}Downloading source packages${cc_normal}"

mkdir -p $DOWNLOADS
cd $DOWNLOADS

if [[ $IRCD_ROLE = *download* ]] 
then
	[ -f $IRCDFILE ] && echo " - $IRCDFILE exists" || wget $IRCDURL
else
	echo " - ${cc_yellow}Skipping $IRCDFILE${cc_normal}"
fi

if [[ $REDIS_ROLE = *download* ]] 
then
	[ -f $REDISFILE ] && echo " - $REDISFILE exists" || wget $REDISURL
else
	echo " - ${cc_yellow}Skipping $REDISFILE${cc_normal}"
fi

if [[ $NODEJS_ROLE = *download* ]] 
then
	[ -f $NODEJSFILE ] && echo " - $NODEJSFILE exists" || wget $NODEJSURL
else
	echo " - ${cc_yellow}Skipping $NODEJSFILE${cc_normal}"
fi

if [[ $VARNISH_ROLE = *download* ]] 
then
	[ -f $VARNISHFILE ] && echo " - $VARNISHFILE exists" || wget $VARNISHURL
else
	echo " - ${cc_yellow}Skipping $VARNISHFILE${cc_normal}"
fi

if [[ $NGINX_ROLE = *download* ]] 
then
	[ -f $NGINXFILE ] && echo " - $NGINXFILE exists" || wget $NGINXURL
else
	echo " - ${cc_yellow}Skipping $NGINXFILE${cc_normal}"
fi

if [[ $HTTPD_ROLE = *download* ]] 
then
	[ -f $HTTPDFILE ] && echo " - $HTTPDFILE exists" || wget $HTTPDURL
else
	echo " - ${cc_yellow}Skipping $HTTPDFILE${cc_normal}"
fi

if [[ $FTPD_ROLE = *download* ]] 
then
	[ -f $FTPDFILE ] && echo " - $FTPDFILE exists" || wget $FTPDURL
else
	echo " - ${cc_yellow}Skipping $FTPDFILE${cc_normal}"
fi

if [[ $MYSQLD_ROLE = *download* ]] 
then
	[ -f $MYSQLDFILE ] && echo " - $MYSQLDFILE exists" || wget $MYSQLDURL
else
	echo " - ${cc_yellow}Skipping $MYSQLDFILE${cc_normal}"
fi


echo $PHPFILE  


if [[ $PHP_ROLE = *download* ]] 
then
	[ -f $PHPFILE ] && echo " - $PHPFILE exists" || wget $PHPURL
else
	echo " - ${cc_yellow}Skipping $PHPFILE${cc_normal}"
fi


cd ..

###############################################################################
#
# Install IRCD
# 

if [ "$IRCD_ROLE" != "" ]
then
	echo "$*** ${cc_cyan}Installing IRCD ($IRCDFOLDER)${cc_normal}"
	
	create_user_and_stop_service $IRCDUSER $IRCDPROCESS

	if [[ $IRCD_ROLE = *compile* ]]
	then
		cp $DOWNLOADS/$IRCDFILE $HOMEROOT/$IRCDUSER/
		chown $IRCDUSER.$GROUP $HOMEROOT/$IRCDUSER
		cd  $HOMEROOT/$IRCDUSER
		echo " - Deleting old instance"
		rm -rf $IRCDFOLDER
		rm -rf inspircd
		echo " - Uncompressing"
		tar -xjf $IRCDFILE
		mv inspircd $IRCDFOLDER # For some reason this package unzips in 'inspircd' so we tweak that..
		echo " - Building"
		cd $IRCDFOLDER
		./configure  --uid=$IRCDUSER --disable-interactive
		make
		if [[ $IRCD_ROLE = *install* ]]
		then
			echo " - Installing"
			make install
		fi
	fi

	#
	# Generate configure scripts
	#
	
	if [[ $IRCD_ROLE = *configure* ]]
	then
		# ---- IRCD CONFIG -- START ----	
		
		cat > $IRCDCONFIG << EOF
<config format="xml">
<define name="bindip" value="0.0.0.0">
<define name="localips" value="&bindip;/24">
<server name="ircd.thumbwhere.com" description="ThumbWhere IRCD Server" network="ThumbWhere">
<admin name="ThumbWhere" nick="ThumbWhere" email="thumbwhere@thumbwhere.com">
<bind address="&bindip;" port="6697" type="clients" ssl="openssl" >
<bind address="&bindip;" port="6660-6669" type="clients">
<bind address="&bindip;" port="7000,7001" type="servers">
<bind address="&bindip;" port="7005" type="servers" ssl="openssl">
<power diepass="" restartpass="">
<connect deny="69.254.*">
<connect deny="3ffe::0/32" reason="The 6bone address space is deprecated">
<connect name="main" allow="*" maxchans="30" timeout="10" pingfreq="120" hardsendq="1048576" softsendq="8192" recvq="8192" threshold="10" commandrate="1000" fakelag="on" localmax="3" globalmax="3" useident="no" limit="5000" modes="+x">
# OPERS
<class name="Shutdown" commands="DIE RESTART REHASH LOADMODULE UNLOADMODULE RELOAD GUNLOADMODULE GRELOADMODULE SAJOIN SAPART SANICK SAQUIT SATOPIC" privs="users/auspex channels/auspex servers/auspex users/mass-message channels/high-join-limit channels/set-permanent users/flood/no-throttle users/flood/increased-buffers" usermodes="*" chanmodes="*">
<class name="ServerLink" commands="CONNECT SQUIT CONNECT MKPASSWD ALLTIME SWHOIS CLOSE JUMPSERVER LOCKSERV" usermodes="*" chanmodes="*" privs="servers/auspex">
<class name="BanControl" commands="KILL GLINE KLINE ZLINE QLINE ELINE TLINE RLINE CHECK NICKLOCK SHUN CLONES CBAN" usermodes="*" chanmodes="*">
<class name="OperChat" commands="WALLOPS GLOBOPS SETIDLE" usermodes="*" chanmodes="*" privs="users/mass-message">
<class name="HostCloak" commands="SETHOST SETIDENT SETNAME CHGHOST CHGIDENT TAXONOMY" usermodes="*" chanmodes="*" privs="users/auspex">
<type name="NetAdmin" classes="OperChat BanControl HostCloak Shutdown ServerLink" vhost="netadmin.ircd.thumbwhere.com" modes="+s +cCqQ">
<type name="GlobalOp" classes="OperChat BanControl HostCloak ServerLink" vhost="ircdop.ircd.thumbwhere.com">
<type name="Helper" classes="HostCloak" vhost="helper.ircd.thumbwhere.com">
<oper name="ThumbWhere" hash="sha256" password="accff88f4b5fa17ac2bdf6fb7428119f999cf9bed698663a65a5681a4023d4fe" host="*@*" type="NetAdmin">
# LINKS
#<link name="hub.ircd.thumbwhere.com" ipaddr="hub.ircd.thumbwhere.com" port="7000" allowmask="*/24"  timeout="300"  ssl="openssl"  bind="&bindip;" statshidden="no" hidden="no" sendpass="outgoing!password" recvpass="incoming!password">
#<link name="services.ircd.thumbwhere.com" ipaddr="localhost" port="7000" allowmask="127.0.0.0/8" sendpass="password" recvpass="password">
#<autoconnect period="300" server="hub.ircd.thumbwhere.com">
#<autoconnect period="120" server="hub-backup.ircd.thumbwhere.com ">
<uline server="services.ircd.thumbwhere.com" silent="yes">
<files motd="$IRCDCONFIG.motd" rules="$IRCDCONFIG.rules">
#<execfiles rules="wget -O - http://www.example.com/rules.txt">
<channels users="20" opers="60">
<pid file="$IRCDPID">
<banlist chan="*" limit="69">
#<disabled commands="TOPIC MODE" usermodes="" chanmodes="" fakenonexistant="yes">
<options prefixquit="Quit: " suffixquit="" prefixpart="&quot;" suffixpart="&quot;" syntaxhints="yes" cyclehosts="yes" cyclehostsfromuser="no" ircdumsgprefix="no" announcets="yes" allowmismatched="no" defaultbind="auto" hostintopic="yes" pingwarning="15" serverpingfreq="60" defaultmodes="nt" moronbanner="You're banned! Email abuse@thumbwhere.com with the ERROR line below for help." exemptchanops="nonick:v flood:o" invitebypassmodes="yes">
<performance netbuffersize="10240" maxwho="4096" somaxconn="128" softlimit="12800" quietbursts="yes" nouserdns="no">
<security announceinvites="dynamic" hidemodes="eI" hideulines="no" flatlinks="no" hidewhois="" hidebans="no" hidekills="" hidesplits="no" maxtargets="20" customversion="" operspywhois="no" runasuser="$IRCDUSER" restrictbannedusers="yes" genericoper="no" userstats="Pu">
<limits maxnick="31" maxchan="64" maxmodes="20" maxident="11" maxquit="255" maxtopic="307" maxkick="255" maxgecos="128" maxaway="200">
<log method="file" type="* -USERINPUT -USEROUTPUT" level="default" target="ircd.log">
<whowas groupsize="10" maxgroups="100000" maxkeep="3d">
<badnick nick="ChanServ" reason="Reserved For Services">
<badnick nick="NickServ" reason="Reserved For Services">
<badnick nick="OperServ" reason="Reserved For Services">
<badnick nick="MemoServ" reason="Reserved For Services">
<badhost host="root@*" reason="Don't ircd as root!">
<badhost host="*@172.32.0.0/16" reason="This subnet is bad.">
<exception host="*@ircdop.host.com" reason="Opers hostname">
<insane hostmasks="no" ipmasks="no" nickmasks="no" trigger="95.5">
# MODULES
<module name="m_md5.so">
<module name="m_sha256.so">
<module name="m_ripemd160.so">
<module name="m_password_hash.so">
<module name="m_abbreviation.so">
<module name="m_alias.so">
<alias text="NICKSERV" replace="PRIVMSG NickServ :$2-" requires="NickServ" uline="yes">
<alias text="CHANSERV" replace="PRIVMSG ChanServ :$2-" requires="ChanServ" uline="yes">
<alias text="OPERSERV" replace="PRIVMSG OperServ :$2-" requires="OperServ" uline="yes" operonly="yes">
<alias text="BOTSERV" replace="PRIVMSG BotServ :$2-" requires="BotServ" uline="yes">
<alias text="HOSTSERV" replace="PRIVMSG HostServ :$2-" requires="HostServ" uline="yes">
<alias text="MEMOSERV" replace="PRIVMSG MemoServ :$2-" requires="MemoServ" uline="yes">
<module name="m_autoop.so">
<module name="m_banexception.so">
<module name="m_banredirect.so">
<module name="m_botmode.so">
<module name="m_chanprotect.so">
<chanprotect noservices="no" qprefix="~" aprefix="&amp;" deprotectself="yes" deprotectothers="yes">
<module name="m_check.so">
<module name="m_spanningtree.so">
EOF

		cat > $IRCDCONFIG.rules << EOF
These are the rules.
EOF

		cat > $IRCDCONFIG.motd << EOF
This is the MOTD
EOF
		# ---- IRCD CONFIG -- END ----


		# ---- IRCD CONTROL SCRIPT -- START --

		cat > /etc/init.d/$IRCDUSER-server << EOF
#!/bin/sh
### BEGIN INIT INFO
# Provides:	  $IRCDUSER-server
# Required-Start:	\$network \$syslog \$time
# Required-Stop:	 \$syslog
# Should-Start:	  \$local_fs
# Should-Stop:	   \$local_fs
# Default-Start:	 2 3 4 5
# Default-Stop:	  0 1 6
# Short-Description: Controls the ircd server
# Description:	   Controls the ircd server.
### END INIT INFO
# GPL Licensed

DAEMON="/usr/sbin/inspircd"
PIDFILE="$IRCDPID"
LOG="/var/log/inspircd.log"
CONFIG="$IRCDCONFIG"
ARGS="--logfile \$LOG --config \$CONFIG"
USER="$IRCDUSER"
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
SERVICENAME=$IRCDUSER-service
PROCESSNAME=$IRCDPROCESS
DESC="IRC Server"

# Source function library
. /lib/lsb/init-functions

os="$os"

if [ "\$os" = "centos" ]
then
	# source function library
	. /etc/rc.d/init.d/functions
fi

if [ ! -x "\$DAEMON" ]; then echo "could not locate \$DAEMON - exiting." ; exit 0; fi

if [ -f "\$PIDFILE" ]; then
	PIDN="\`cat \"\$PIDFILE\" 2> /dev/null\`"
fi

start_ircd()
{
	[ -f "\$PIDFILE" ] || ( touch "\$PIDFILE" ; chown "\$USER" "\$PIDFILE" )
	[ -f "\$LOG" ] || ( touch "\$LOG" ; chown "\$USER:thumbwhere" "\$LOG" ; chmod 0640 "\$LOG" )
	export LD_LIBRARY_PATH=/usr/lib/inspircd
	
	# Start based on OS type
	if [ "\$os" = "centos" ]
	then 	
		if su - \$USER -c "\$DAEMON \$ARGS"
 		then
						echo " ${cc_green}OK${cc_normal}"
				else
						echo -n " ${cc_red}FAIL${cc_normal} ("

						if [ ! -z "\$PIDN" ] && killall -0 \$PROCESSNAME 2> /dev/null
						then
								echo -n "${cc_yellow}Seems \$PROCESSNAME is already running.${cc_normal}"

								# and just to be sure the pids are not out of whack
								killall -2 \$PROCESSNAME 2> /dev/null
						else
								echo -n "${cc_yellow}Looks like \$PROCESSNAME is not already running.${cc_normal}"
						fi
			echo -n ")"

						exit 1
				fi

		
	elif [ "\$os" = "debian" ] || [ "\$os" = "ubuntu" ]
	then
		if start-stop-daemon --start --quiet --oknodo --chuid "\$USER" --pidfile "\$PIDFILE" --exec "\$DAEMON" --  \$ARGS
		then
						echo " ${cc_green}OK${cc_normal}"
				else
						echo " ${cc_red}FAIL${cc_normal} (is it already running?)"
						exit 1
				fi

	fi
}

stop_ircd()
{

	# Stop based on OS type
	if [ "\$os" = "centos" ]
	then
 		if [ ! -z "\$PIDN" ] && killall -0 \$PROCESSNAME 2> /dev/null
		then
			if killall -2 \$PROCESSNAME 2> /dev/null
			then
				 echo " ${cc_green}OK${cc_normal}"
			else
				 echo " ${cc_cyan}WARN${cc_normal}"
			fi
		else
			echo -n " ${cc_cyan}WARN${cc_normal}"
			echo " ${cc_yellow}Looks like \$PROCESSNAME is not running.${cc_normal}"
		fi
	elif [ "\$os" = "debian" ] || [ "\$os" = "ubuntu" ]
	then

		if start-stop-daemon --stop --quiet --pidfile \$PIDFILE --retry 10 --exec \$DAEMON 2> /dev/null
		then		
			echo " ${cc_green}OK${cc_normal}"
	   		# and just to be sure the pids are not out of whack
	   		killall -2 \$PROCESSNAME 2> /dev/null
		else
			echo -n " ${cc_cyan}WARN${cc_normal} ("
 			if [ ! -z "\$PIDN" ] && killall -0 \$PROCESSNAME 2> /dev/null
 			then
				echo -n "${cc_yellow}Seems \$PROCESSNAME is running but not as pid '\$PIDN' we were expecting. Killing all.${cc_normal}"
				# and just to be sure the pids are not out of whack
				killall -2 \$PROCESSNAME 2> /dev/null
			else
				echo -n "${cc_yellow}Looks like \$PROCESSNAME is not running.${cc_normal}"
			fi

			echo ")"
		fi
	fi

	# 5 seconds grace
	sleep 5

	# And finally, to ensure there are no issues
	killall -9 \$PROCESSNAME 2> /dev/null

	rm -f "\$PIDFILE"
	return 0
}

reload_ircd()
{
	if [ ! -z "\$PIDN" ] && kill -0 \$PIDN 2> /dev/null; then
		kill -HUP \$PIDN >/dev/null 2>&1 || return 1
		return 0
	else
		echo "Error: $DAEMON is not running."
		return 1
	fi
}

case "\$1" in
  start)
	#if [ "\$INSPIRCD_ENABLED" != "1" ]; then
	#	echo "Please configure inspircd first and edit /etc/default/inspircd, otherwise inspircd won't start"
	#	exit 0
	#fi
	echo -n "Starting \$DESC (\$PROCESSNAME): "
	start_ircd
	;;
  stop)
	echo -n "Stopping \$DESC (\$PROCESSNAME): "
	stop_ircd
	;;
  force-reload|reload)
	echo -n "Reloading \$DESC (\$PROCESSNAME): "
	reload_ircd
	;;
  restart)
	echo "Restarting \$DESC (\$PROCESSNAME): "
	\$0 stop
	sleep 2s
	\$0 start
	;;
  cron)
	start_ircd || echo "Inspircd not running, starting it"
	;;

  *)
	echo "Usage: \$0 {start|stop|restart|reload|force-reload|cron}"
	exit 1
esac
EOF
		# ---- IRCD CONTROL SCRIPT --- END ---
		
		chmod +x /etc/init.d/$IRCDUSER-server
		chown root.root /etc/init.d/$IRCDUSER-server
		
	fi

	echo " - Setting permissions"
	chown -R $IRCDUSER.$GROUP $HOMEROOT/$IRCDUSER/
	
	# Enable or disable...
	enable_disable $IRCDUSER $IRCD_ROLE

fi


###############################################################################
#
# Install Redis
#

if [ "$REDIS_ROLE" != "" ]
then
	echo "*** ${cc_cyan}Installing REDIS ($REDISFILE)${cc_normal}"

	create_user_and_stop_service $REDISUSER $REDISPROCESS

	if [[ $REDIS_ROLE = *compile* ]]
	then

		cp $DOWNLOADS/$REDISFILE $HOMEROOT/$REDISUSER/
		chown $REDISUSER.$GROUP $HOMEROOT/$REDISUSER
		cd  $HOMEROOT/$REDISUSER
		echo " - Deleting old instance"
		rm -rf $REDISFOLDER
		echo " - Uncompressing"
		tar -xvf $REDISFILE
		echo " - Building"
		cd $REDISFOLDER
		make
		if [[ $REDIS_ROLE = *test* ]]
			then
			echo " - Testing"
			make test
		fi
		if [[ $REDIS_ROLE = *install* ]]
		then		
			echo " - Installing"
			make install
		fi
	fi



	if [[ $REDIS_ROLE = *configure* ]]
	then

		# 
		# Generate configure scripts
		#	

		echo " - Configuring"

# --- REDIS CONTROL SCRIPT -- START ----
	
	cat > /etc/init.d/$REDISUSER-server << EOF
#! /bin/sh
### BEGIN INIT INFO
# Provides:		 $REDISUSER-server
# Required-Start:	   $syslog $remote_fs
# Required-Stop:	$syslog $remote_fs
# Should-Start:	 $local_fs
# Should-Stop:	  $local_fs
# Default-Start:	2 3 4 5
# Default-Stop:	 0 1 6
# Short-Description:	$REDISUSER-server - Persistent key-value db for ThumbWhere
# Description:	  $REDISUSER-server - Persistent key-value db for ThumbWhere
### END INIT INFO

# Source function library
. /lib/lsb/init-functions

os="$os"

if [ "\$os" = "centos" ]
then
	# source function library
	. /etc/rc.d/init.d/functions
fi


PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/local/bin/redis-server
DAEMON_ARGS=$REDISCONFIG
USER=\$REDISUSER
PROCESSNAME=redis-server
DESC=redis-server
PIDFILE=$REDISPID
DESC="Redis"

test -x \$DAEMON || exit 0

set -e

if [ -f "\$PIDFILE" ]; then
	REDISPIDN="\`cat \"\$PIDFILE\" 2> /dev/null\`"
fi

case "\$1" in
  start)
	echo -n "Starting \$DESC (\$PROCESSNAME): "
	
	# Start based on OS type
	if [ "\$os" = "centos" ]
	then 	
		if su - \$USER -c "\$DAEMON \$DAEMON_ARGS" 2> /dev/null
		then
			echo " ${cc_green}OK${cc_normal}"
		else
			echo " ${cc_red}FAIL${cc_normal}"
			exit 1
		fi
	elif [ "\$os" = "debian" ] || [ "\$os" = "ubuntu" ]
	then	
		if start-stop-daemon --start --quiet --umask 007 --pidfile \$PIDFILE --chuid $REDISUSER:$GROUP --exec \$DAEMON -- \$DAEMON_ARGS  2> /dev/null
 		then
			echo " ${cc_green}OK${cc_normal}"
		else
			echo " ${cc_red}FAIL${cc_normal}"
			exit 1
		fi
	fi
	;;
  stop)
	echo -n "Stopping \$DESC (\$PROCESSNAME): "

	if redis-cli shutdown  2> /dev/null
	then
		echo " ${cc_green}OK${cc_normal}"
	else
		echo " ${cc_red}FAIL${cc_normal}"
	fi
	rm -f \$PIDFILE
	;;

  restart|force-reload)
	echo "Restarting \$DESC (\$PROCESSNAME): "
	\${0} stop
	\${0} start
	;;
  *)
	echo "Usage: /etc/init.d/\$PROCESSNAME {start|stop|restart|force-reload}" >&2
	exit 1
	;;
esac

exit 0
EOF

		chmod +x /etc/init.d/$REDISUSER-server
		chown root.root /etc/init.d/$REDISUSER-server
		
		# ---- REDIS CONTROL SCRIPT -- END ----


		# ---- REDIS CONFIG -- START ----

		cat > $REDISCONFIG << EOF
daemonize yes
pidfile  $REDISPID
port 6379
bind 127.0.0.1
timeout 300
loglevel notice
logfile $REDISLOGS/redis-server.log
databases 16
save 900 1
save 300 10
save 60 10000
rdbcompression yes
dbfilename thumbwhere.rdb
dir $HOMEROOT/$REDISUSER
# slaveof <masterip> <masterport>
# masterauth <master-password>
# requirepass foobared
# maxclients 128
# maxmemory <bytes>
appendonly no
appendfsync always
# appendfsync everysec
# appendfsync no
glueoutputbuf yes
#shareobjects no
#shareobjectspoolsize 1024
EOF
		# ---- REDIS CONFIG -- END ----
 	fi

	echo " - Setting permissions"
	chown -R $REDISUSER.$GROUP $HOMEROOT/$REDISUSER/
	
	# Enable or disable...
	enable_disable $REDISUSER $REDIS_ROLE

fi

###############################################################################
#
# Install NODEJS
#

if [ "$NODEJS_ROLE" != '' ]
then
	echo "*** ${cc_cyan}Installing NODEJS ($NODEJSFOLDER)${cc_normal}"

	if [ "`id -un $NODEJSUSER`" != "$NODEJSUSER" ]
	then
		echo " - Adding user $NODEJSUSER"
		useradd $NODEJSUSER -m -g $GROUP
	fi

	if [[ $NODEJS_ROLE = *compile* ]]
	then
		cp $DOWNLOADS/$NODEJSFILE $HOMEROOT/$NODEJSUSER/
		chown $NODEJSUSER.$GROUP $HOMEROOT/$NODEJSUSER
		cd  $HOMEROOT/$NODEJSUSER
		echo " - Deleting old instance"
		rm -rf $NODEJSFOLDER
		echo " - Uncompressing"
		tar -xzf $NODEJSFILE
		echo " - Building"
		cd $NODEJSFOLDER
		./configure --shared-zlib #--shared-cares
		make
		#echo " - Testing"
		#make test
	fi

	if [[ $NODEJS_ROLE = *install* ]]
	then
		echo " - Installing"
		make install
	fi

	if [[ $NODEJS_ROLE = *configure* ]]
	then
		echo " - Configuring"
	fi

	echo " - Setting permissions"
	chown -R $NODEJSUSER.$GROUP $HOMEROOT/$NODEJSUSER/

fi

###############################################################################
#
# Install VARNISH
#

if [ "$VARNISH_ROLE" != "" ]
then
	echo "*** ${cc_cyan}Installing VARNISH ($VARNISHFOLDER)${cc_normal}"

	create_user_and_stop_service $VARNISHUSER $VARNISHPROCESS

	if [[ $VARNISH_ROLE = *compile* ]]
	then
		cp $DOWNLOADS/$VARNISHFILE $HOMEROOT/$VARNISHUSER/
		chown $VARNISHUSER.$GROUP $HOMEROOT/$VARNISHUSER
		cd  $HOMEROOT/$VARNISHUSER
		echo " - Deleting old instance"
		rm -rf $VARNISHFOLDER
		echo " - Uncompressing"
		tar -xzf $VARNISHFILE
		echo " - Building"
		cd $VARNISHFOLDER
		./configure 
		make
	
		if [[ $VARNISH_ROLE = *install* ]]
			then
			echo " - Installing"
			make install
		fi
	fi

	if [[ $VARNISH_ROLE = *configure* ]]
		then

		echo " - Configuring"

# ---- VARNISH CONTROL SCRIPT -- START ----

		cat > /etc/init.d/$VARNISHUSER-server << EOF
#! /bin/sh

### BEGIN INIT INFO
# Provides:	  $VARNISHUSER-server
# Required-Start:	\$local_fs \$remote_fs \$network
# Required-Stop:	 \$local_fs \$remote_fs \$network
# Default-Start:	 2 3 4 5
# Default-Stop:	  0 1 6
# Short-Description: Start HTTP accelerator
# Description:	   This script provides a server-side cache
#			to be run in front of a httpd and should
#			listen on port 80 on a properly configured
#			system
### END INIT INFO

# Source function library
. /lib/lsb/init-functions

os="$os"

if [ "\$os" = "centos" ]
then
# source function library
. /etc/rc.d/init.d/functions
fi

PROCESSNAME=varnishd
DESC="Varnish"
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin/
DAEMON=/usr/local/sbin/varnishd
PIDFILE=$VARNISHPID

test -x \$DAEMON || echo "Could not locate \$DAEMON" exit 0

# Open files (usually 1024, which is way too small for varnish)
ulimit -n \${NFILES:-131072}

# Maxiumum locked memory size for shared memory log
ulimit -l \${MEMLOCK:-82000}

DAEMON_ARGS="-f $VARNISHCONFIG -P \$PIDFILE"

if [ -f "\$PIDFILE" ]; then
	PIDN="\`cat \"\$PIDFILE\" 2> /dev/null\`"
fi

# Ensure we have a PATH
export PATH="\${PATH:+\$PATH:}/usr/sbin:/usr/bin:/sbin:/bin"

start_varnishd() {
	# Start based on OS type
	if [ "\$os" = "centos" ]
	then 	
		echo -n "Starting \$DESC" "\$PROCESSNAME"
		if su - \$VARNISHUSER -c "\$DAEMON \$DAEMON_ARGS"
		then
				 	echo " ${cc_green}OK${cc_normal}"
		else
			echo " ${cc_red}FAIL${cc_normal}"
			exit 1
		fi
	elif [ "\$os" = "debian" ] || [ "\$os" = "ubuntu" ]
	then	
		log_daemon_msg "Starting \$DESC" "\$PROCESSNAME"
		if start-stop-daemon --start --quiet --pidfile \${PIDFILE} --exec \${DAEMON} -- \$DAEMON_ARGS
		then
			echo " ${cc_green}OK${cc_normal}"
		else
			echo " ${cc_red}FAIL${cc_normal} (is it already running?)"
			exit 1
		fi
	fi
}

disabled_varnishd() {
	log_daemon_msg "Not starting \$DESC" "\$PROCESSNAME"
	log_progress_msg "disabled in /etc/default/varnish"
	log_end_msg 0
}

stop_varnishd() {

	if [ "\$os" = "centos" ]
	then 	
		if [ ! -z "\$PIDN" ] && kill -0 \$PIDN 2> /dev/null 
		then
			if kill -2 \$PIDN >/dev/null 2>&1  2> /dev/null
			then
				echo " ${cc_green}OK${cc_normal}"
			else
				echo " ${cc_red}FAIL${cc_normal}"
			fi
		else
				echo -n " ${cc_cyan}WARN${cc_normal}"
				echo " ${cc_yellow}Looks like \$PROCESSNAME is not running.${cc_normal}"
		fi				
	elif [ "\$os" = "debian" ] || [ "\$os" = "ubuntu" ]
	then
		if start-stop-daemon --stop --quiet --pidfile \$PIDFILE --retry 10 --exec \$DAEMON 2> /dev/null
		then		
			echo " ${cc_green}OK${cc_normal}"

			# and just to be sure the pids are not out of whack
			killall -2 \$PROCESSNAME 2> /dev/null
		else
			echo -n " ${cc_cyan}WARN${cc_normal} ("

 			if [ ! -z "\$PIDN" ] && killall -0 \$PROCESSNAME 2> /dev/null
	 		then
				echo -n "${cc_yellow}Seems \$PROCESSNAME is running but not as pid '\$PIDN' we were expecting. Killing all.${cc_normal}"

				# and just to be sure the pids are not out of whack
				killall -2 \$PROCESSNAME 2> /dev/null
			else
				echo -n "${cc_yellow}Looks like \$PROCESSNAME is not running.${cc_normal}"
			fi

			echo ")"
		fi

	fi

	# 5 seconds grace	
	sleep 5

		# And finally, to ensure there are no issues
		killall -9 \$PROCESSNAME 2> /dev/null
	

	# clean out the pid file anyway...
	rm -f \$PIDFILE
}

reload_varnishd() {
	echo "Reloading \$DESC" "\$PROCESSNAME"
	if /usr/share/varnish/reload-vcl -q; then
		echo " ${cc_green}OK${cc_normal}"
	else
		echo " ${cc_red}FAIL${cc_normal}"
	fi
}

status_varnishd() {
	status_of_proc -p "\${PIDFILE}" "\${DAEMON}" "\${PROCESSNAME}"
}

case "\$1" in
	start)
	echo -n "Starting \$DESC (\$PROCESSNAME): "
	start_varnishd
	;;
	stop)
	echo -n "Stopping \$DESC (\$PROCESSNAME): "
	stop_varnishd
	;;
	reload)
	echo -n "Reloading \$DESC (\$PROCESSNAME): "
	reload_varnishd
	;;
	status)
	status_varnishd
	;;
	restart|force-reload)
	 echo "Restarting \$DESC (\$PROCESSNAME): "
	\$0 stop
	\$0 start
	;;
	*)
	echo  "Usage: \$0 {start|stop|restart|force-reload}"
	exit 1
	;;
esac

exit 0
EOF

 		chmod +x /etc/init.d/$VARNISHUSER-server
		chown root.root /etc/init.d/$VARNISHUSER-server

		# ---- VARNISH CONTROL SCRIPT -- END ----

		# ---- VARNISH CONFIG -- START ----

		cat > $VARNISHCONFIG << EOF
backend default {
	.host = "0.0.0.0";
	.port = "80";
}
EOF

		# ---- VARNISH CONFIG -- END ----

	fi

	echo " - Setting permissions"
	chown -R $VARNISHUSER.$GROUP $HOMEROOT/$VARNISHUSER/

	# Enable or disable...
	enable_disable $VARNISHUSER $VARNISH_ROLE

fi



###############################################################################
#
# Install NGINX
#

if [ "$NGINX_ROLE" != "" ]
then
	echo "*** ${cc_cyan}Installing NGINX ($NGINXFOLDER)${cc_normal}"

	create_user_and_stop_service $NGINXUSER $NGINXPROCESS

	if [[ $NGINX_ROLE = *compile* ]]
		then
		cp $DOWNLOADS/$NGINXFILE $HOMEROOT/$NGINXUSER/
		chown $NGINXUSER.$GROUP $HOMEROOT/$NGINXUSER
		cd  $HOMEROOT/$NGINXUSER
		echo " - Deleting old instance"
		rm -rf $NGINXFOLDER
		echo " - Uncompressing"
		tar -xzf $NGINXFILE
		echo " - Building"
		cd $NGINXFOLDER
		./configure --prefix=$NGINXROOT
		make
	
		if [[ $NGINX_ROLE = *install* ]]
			then
			echo " - Installing"
			make install
		fi
	fi


	if [[ $NGINX_ROLE = *configure* ]]
	then

		echo " - Configuring"

		# ---- NGINX CONTROL SCRIPT -- START ----

		cat > /etc/init.d/$NGINXUSER-server << EOF
#! /bin/sh

### BEGIN INIT INFO
# Provides:	  $NGINXUSER-server
# Required-Start:	\$local_fs \$remote_fs \$network
# Required-Stop:	 \$local_fs \$remote_fs \$network
# Default-Start:	 2 3 4 5
# Default-Stop:	  0 1 6
# Short-Description: Start HTTP accelerator
# Description:	   This script provides a server-side cache
#			to be run in front of a httpd and should
#			listen on port 80 on a properly configured
#			system
### END INIT INFO

# Source function library
. /lib/lsb/init-functions

os="$os"

if [ "\$os" = "centos" ]
then
# source function library
. /etc/rc.d/init.d/functions
fi

PROCESSNAME=$NGINXPROCESS
DESC="Nginx"
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin/
DAEMON=$NGINXROOT/sbin/$NGINXPROCESS
PIDFILE=$NGINXPID

test -x \$DAEMON || echo "Could not locate \$DAEMON" exit 0

# Open files (usually 1024, which is way too small for nginx)
ulimit -n \${NFILES:-131072}

# Maxiumum locked memory size for shared memory log
ulimit -l \${MEMLOCK:-82000}

DAEMON_ARGS=""

if [ -f "\$PIDFILE" ]; then
	PIDN="\`cat \"\$PIDFILE\" 2> /dev/null\`"
fi

# Ensure we have a PATH
export PATH="\${PATH:+\$PATH:}/usr/sbin:/usr/bin:/sbin:/bin"

start_nginxd() {
	# Start based on OS type
	if [ "\$os" = "centos" ]
	then 	
		echo -n "Starting \$DESC" "\$PROCESSNAME"
		if su - \$NGINXUSER -c "\$DAEMON \$DAEMON_ARGS"
		then
				 	echo " ${cc_green}OK${cc_normal}"
		else
			echo " ${cc_red}FAIL${cc_normal}"
			exit 1
		fi
	elif [ "\$os" = "debian" ] || [ "\$os" = "ubuntu" ]
	then	
		log_daemon_msg "Starting \$DESC" "\$PROCESSNAME"
		if start-stop-daemon --start --quiet --pidfile \${PIDFILE} --exec \${DAEMON} -- \$DAEMON_ARGS
		then
			echo " ${cc_green}OK${cc_normal}"
		else
			echo " ${cc_red}FAIL${cc_normal} (is it already running?)"
			exit 1
		fi
	fi
}

disabled_nginxd() {
	log_daemon_msg "Not starting \$DESC" "\$PROCESSNAME"
	log_progress_msg "disabled in /etc/default/nginx"
	log_end_msg 0
}

stop_nginxd() {

	if [ "\$os" = "centos" ]
	then 	
		if [ ! -z "\$PIDN" ] && kill -0 \$PIDN 2> /dev/null 
		then
			if kill -2 \$PIDN >/dev/null 2>&1  2> /dev/null
			then
				echo " ${cc_green}OK${cc_normal}"
			else
				echo " ${cc_red}FAIL${cc_normal}"
			fi
		else
			echo -n " ${cc_cyan}WARN${cc_normal}"
			echo " ${cc_yellow}Looks like \$PROCESSNAME is not running.${cc_normal}"						
		fi
	elif [ "\$os" = "debian" ] || [ "\$os" = "ubuntu" ]
	then
		if start-stop-daemon --stop --quiet --pidfile \$PIDFILE --retry 10 --exec \$DAEMON 2> /dev/null
		then		
			echo " ${cc_green}OK${cc_normal}"

				# and just to be sure the pids are not out of whack
				killall -2 \$PROCESSNAME 2> /dev/null
		else
			echo -n " ${cc_cyan}WARN${cc_normal} ("

 			if [ ! -z "\$PIDN" ] && killall -0 \$PROCESSNAME 2> /dev/null
	 		then
				echo -n "${cc_yellow}Seems \$PROCESSNAME is running but not as pid '\$PIDN' we were expecting. Killing all.${cc_normal}"
				# and just to be sure the pids are not out of whack
				killall -2 \$PROCESSNAME 2> /dev/null
			else
				echo -n "${cc_yellow}Looks like \$PROCESSNAME is not running.${cc_normal}"
			fi

			echo ")"
		fi

	fi

	# 5 seconds grace	
	sleep 5

		# And finally, to ensure there are no issues
		killall -9 \$PROCESSNAME 2> /dev/null
	

	# clean out the pid file anyway...
	rm -f \$PIDFILE
}

reload_nginxd() {
	echo "Reloading \$DESC" "\$PROCESSNAME"
	if /usr/share/nginx/reload-vcl -q; then
		echo " ${cc_green}OK${cc_normal}"
	else
		echo " ${cc_red}FAIL${cc_normal}"
	fi
}

status_nginxd() {
	status_of_proc -p "\${PIDFILE}" "\${DAEMON}" "\${PROCESSNAME}"
}

case "\$1" in
	start)
	echo -n "Starting \$DESC (\$PROCESSNAME): "
	start_nginxd
	;;
	stop)
	echo -n "Stopping \$DESC (\$PROCESSNAME): "
	stop_nginxd
	;;
	reload)
	echo -n "Reloading \$DESC (\$PROCESSNAME): "
	reload_nginxd
	;;
	status)
	status_nginxd
	;;
	restart|force-reload)
	 echo "Restarting \$DESC (\$PROCESSNAME): "
	\$0 stop
	\$0 start
	;;
	*)
	echo  "Usage: \$0 {start|stop|restart|force-reload}"
	exit 1
	;;
esac

exit 0
EOF

 		chmod +x /etc/init.d/$NGINXUSER-server
		chown root.root /etc/init.d/$NGINXUSER-server
				

		# ---- NGINX CONTROL SCRIPT -- END ----

		# ---- NGINX CONFIG -- START ----

		echo "Writing $NGINXCONFIG"

		cat > $NGINXCONFIG << EOF

#user  $NGINXUSER;
worker_processes  1;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

pid		$NGINXPID;


events {
	worker_connections  1024;
}


http {
	include	   mime.types;
	default_type  application/octet-stream;

	#log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
	#				  '\$status \$body_bytes_sent "\$http_referer" '
	#				  '"\$http_user_agent" "\$http_x_forwarded_for"';

	#access_log  logs/access.log  main;

	sendfile		on;
	#tcp_nopush	 on;

	#keepalive_timeout  0;
	keepalive_timeout  65;

	#gzip  on;

	server {
		listen	   80;
		server_name  localhost;

		#charset koi8-r;

		#access_log  logs/host.access.log  main;

		location / {
			root   html;
			index  index.html index.htm;
		}

		#error_page  404			  /404.html;

		# redirect server error pages to the static page /50x.html
		#
		error_page   500 502 503 504  /50x.html;
		location = /50x.html {
			root   html;
		}

		# proxy the PHP scripts to Apache listening on 127.0.0.1:80
		#
		#location ~ \\.php\$ {
		#	proxy_pass   http://127.0.0.1;
		#}

		# pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
		#
		#location ~ \\.php\$ {
		#	root		   html;
		#	fastcgi_pass   127.0.0.1:9000;
		#	fastcgi_index  index.php;
		#	fastcgi_param  SCRIPT_FILENAME  /scripts\$fastcgi_script_name;
		#	include		fastcgi_params;
		#}

		# deny access to .htaccess files, if Apache's document root
		# concurs with nginx's one
		#
		#location ~ /\\.ht {
		#	deny  all;
		#}
	}


	# another virtual host using mix of IP-, name-, and port-based configuration
	#
	#server {
	#	listen	   8000;
	#	listen	   somename:8080;
	#	server_name  somename  alias  another.alias;

	#	location / {
	#		root   html;
	#		index  index.html index.htm;
	#	}
	#}


	# HTTPS server
	#
	#server {
	#	listen	   443;
	#	server_name  localhost;

	#	ssl				  on;
	#	ssl_certificate	  cert.pem;
	#	ssl_certificate_key  cert.key;

	#	ssl_session_timeout  5m;

	#	ssl_protocols  SSLv2 SSLv3 TLSv1;
	#	ssl_ciphers  HIGH:!aNULL:!MD5;
	#	ssl_prefer_server_ciphers   on;

	#	location / {
	#		root   html;
	#		index  index.html index.htm;
	#	}
	#}

}
EOF

		# ---- NGINX CONFIG -- END ----
	fi
	

	echo " - Setting permissions"
	chown -R $NGINXUSER.$GROUP $HOMEROOT/$NGINXUSER/
	
	
	# Enable or disable...
	enable_disable $NGINXUSER $NGINX_ROLE

fi

###############################################################################
#
# Install HTTPD
#

if [ "$HTTPD_ROLE" != "" ]
then
	echo "*** ${cc_cyan}Installing HTTPD ($HTTPDFOLDER)${cc_normal}"
	
	create_user_and_stop_service $HTTPDUSER $HTTPDPROCESS

	if [[ $HTTPD_ROLE = *compile* ]]
	then

		cp $DOWNLOADS/$HTTPDFILE $HOMEROOT/$HTTPDUSER/
		chown $HTTPDUSER.$GROUP $HOMEROOT/$HTTPDUSER/
		cd  $HOMEROOT/$HTTPDUSER
		echo " - Deleting old instance"
		rm -rf $HTTPDFOLDER
		echo " - Uncompressing"
		tar -xzf $HTTPDFILE
		echo " - Building"
		cd $HTTPDFOLDER
		./configure  --prefix=$HTTPDROOT --enable-so --enable-cgi --enable-info --enable-rewrite --enable-speling --enable-usertrack --enable-deflate --enable-ssl --enable-mime-magic
		make
	fi

	if [[ $HTTPD_ROLE = *install* ]]
	then
		echo " - Installing"
		make install
	fi


	if [[ $HTTPD_ROLE = *configure* ]]
	then
		echo " - Configuring"

		# ---- INSTALL CONTROL SCRIPTS -- START ----

		echo " - Creating control script."
		cat > /etc/init.d/$HTTPDUSER-server << EOF
#!/bin/sh
### BEGIN INIT INFO
# Provides:	  $HTTPDUSER-server
# Required-Start:	\$network \$syslog \$time
# Required-Stop:	 \$syslog
# Should-Start:	  \$local_fs
# Should-Stop:	   \$local_fs
# Default-Start:	 2 3 4 5
# Default-Stop:	  0 1 6
# Short-Description: Controls the httpd server
# Description:	   Controls the httpd server.
### END INIT INFO
# GPL Licensed

# Source function library
. /lib/lsb/init-functions

DAEMON="$HTTPDROOT/bin/apachectl"
PIDFILE="$HTTPDPID"
LOG="/var/log/inspircd.log"
CONFIG="$HTTPDCONFIG"
USER="$HTTPDUSER"
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
PROCESSNAME="httpd"
DESC="apache2"

os="$os"

if [ "\$os" = "centos" ]
then
	# source function library
	. /etc/rc.d/init.d/functions
fi

# Does the executable exist?
if [ ! -x "\$DAEMON" ]; then echo "could not locate \$DAEMON - exiting." ; exit 0; fi

# Get the pid file
if [ -f "\$PIDFILE" ]; then
	PIDN="\`cat \"\$PIDFILE\" 2> /dev/null\`"
fi

start_httpd()
{
	#start-stop-daemon --start --quiet --oknodo --chuid "\$USER" --pidfile "\$PIDFILE" --exec "\$DAEMON" -- start

		if \$DAEMON start
 		then
						echo " ${cc_green}OK${cc_normal}"
				else
						echo -n " ${cc_red}FAIL${cc_normal} ("

						if [ ! -z "\$PIDN" ] && killall -0 \$PROCESSNAME 2> /dev/null
						then
								echo -n "${cc_yellow}Seems \$PROCESSNAME is already running.${cc_normal}"

								# and just to be sure the pids are not out of whack
								killall -2 \$PROCESSNAME 2> /dev/null
						else
								echo -n "${cc_yellow}Looks like \$PROCESSNAME is not already running.${cc_normal}"
						fi
			echo -n ")"

						exit 1
				fi


}

stop_httpd()
{
	if \$DAEMON stop
 	then
		echo " ${cc_green}OK${cc_normal}"
	else
		echo -n " ${cc_red}FAIL${cc_normal} ("

		if [ ! -z "\$PIDN" ] && killall -0 \$PROCESSNAME 2> /dev/null
				then
					echo -n "${cc_yellow}Seems \$PROCESSNAME is already running.${cc_normal}"

						# and just to be sure the pids are not out of whack
					 	killall -2 \$PROCESSNAME 2> /dev/null
				else
						echo -n "${cc_yellow}Looks like \$PROCESSNAME is not already running.${cc_normal}"
				fi
		echo -n ")"

		fi


	#start-stop-daemon --stop --quiet --pidfile "\$PIDFILE" --exec "\$DAEMON" -- stop
	rm -f "\$PIDFILE"

		# and just to be sure the pids are not out of whack
		killall -2 \$PROCESSNAME 2> /dev/null

	return 0
}

reload_httpd()
{
	if [ ! -z "\$PIDN" ] && kill -0 \$PIDN 2> /dev/null; then
		kill -HUP \$PIDN >/dev/null 2>&1 || return 1
		return 0
	else
		echo "Error: Apache2 is not running."
		return 1
	fi
}

case "\$1" in
  start)
	echo -n "Starting \$DESC (\$PROCESSNAME): "
	start_httpd
	;;
  stop)
	echo -n "Stopping \$DESC (\$PROCESSNAME): "
	stop_httpd
	;;
  force-reload|reload)
	echo -n "Reloading \$DESC (\$PROCESSNAME): "
	reload_httpd 
	;;
  restart)
	echo "Restarting \$DESC (\$PROCESSNAME): "
	\$0 stop
	sleep 2s
	\$0 start
	;;
  cron)
	start_ircd || echo "Inspircd not running, starting it"
	;;

  *)
	echo "Usage: \$0 {start|stop|restart|reload|force-reload|cron}"
	exit 1
esac
EOF
		
		chmod +x /etc/init.d/$HTTPDUSER-server
		chown root.root /etc/init.d/$HTTPDUSER-server

		# ---- INSTALL CONTROL SCRIPTS -- END ----

		# ---- INSTALL CONFIG -- START --
		cat > $HTTPDCONFIG << EOF
ServerRoot "/home/tw-httpd/apache2"
Listen 0.0.0.0:81
User tw-httpd
Group thumbwhere
LoadModule      php5_module      modules/libphp5.so
AddHandler      php5-script     .php
DirectoryIndex  index.html      index.php
AddType         text/html       .php
AddType         application/x-httpd-php-source  phps
<IfModule dir_module>
        DirectoryIndex index.html
</IfModule>
ErrorLog "logs/error_log"
LogLevel warn
<IfModule log_config_module>
        LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
        LogFormat "%h %l %u %t \"%r\" %>s %b" common
        <IfModule logio_module>
          LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio
        </IfModule>
        CustomLog "logs/access_log" common
</IfModule>
DefaultType text/plain
<IfModule mime_module>
        TypesConfig conf/mime.types
        AddType application/x-compress .Z
        AddType application/x-gzip .gz .tgz
</IfModule>
<IfModule ssl_module>
        SSLRandomSeed startup builtin
        SSLRandomSeed connect builtin
</IfModule>
<VirtualHost *:81>
        DocumentRoot /home/tw-drupal/default
#        ServerName 10.0.2.38
        <Directory />
                Options FollowSymLinks
                AllowOverride All
                RewriteEngine on
                RewriteBase /
                RewriteCond %{REQUEST_FILENAME} !-f
                RewriteCond %{REQUEST_FILENAME} !-d
                RewriteRule ^(.*)$ index.php?q= [L,QSA]
        </Directory>
        ErrorLog /home/tw-httpd/apache2/logs/drupal-production-error.log
        LogLevel warn
        CustomLog /home/tw-httpd/apache2/logs/drupal-production-access.log combined
</VirtualHost>
EOF

	# ---- INSTALL CONFIG -- END --

	fi

	#
	# End of configuration
	#

	echo " - Setting permissions"
	chown -R $HTTPDUSER.$GROUP $HOMEROOT/$HTTPDUSER/
		
	# Enable or disable...
	enable_disable $HTTPDUSER $HTTPD_ROLE

fi

#########################################################################################
#
# Install FTPD
#

if [ "$FTPD_ROLE" != "" ]
then
	echo "*** ${cc_cyan}Installing FTPD ($FTPDFOLDER)${cc_normal}"
	
	create_user_and_stop_service $FTPDUSER $FTPDPROCESS

	if [[ $FTPD_ROLE = *compile* ]]
	then
		cp $DOWNLOADS/$FTPDFILE $HOMEROOT/$FTPDUSER/
		chown $FTPDUSER.$GROUP $HOMEROOT/$FTPDUSER
		cd  $HOMEROOT/$FTPDUSER
		echo " - Deleting old instance"
		rm -rf $FTPDFOLDER
		echo " - Uncompressing"
		tar -xzf $FTPDFILE
		echo " - Building"
		cd $FTPDFOLDER
		./configure  --prefix=$FTPDROOT  --enable-ctrls
		make
	fi

	if [[ $FTPD_ROLE = *install* ]]
		then
		echo " - Installing"
		make install
	fi


	if [[ $FTPD_ROLE = *configure* ]]
	then

		echo " - Configuring"

		# ---- INSTALL CONTROL SCRIPTS -- START ----

		echo " - Creating control script."
		cat > /etc/init.d/$FTPDUSER-server << EOF
#!/bin/sh
### BEGIN INIT INFO
# Provides:	  $FTPDUSER-server
# Required-Start:	\$network \$syslog \$time
# Required-Stop:	 \$syslog
# Should-Start:	  \$local_fs
# Should-Stop:	   \$local_fs
# Default-Start:	 2 3 4 5
# Default-Stop:	  0 1 6
# Short-Description: Controls the ftpd server
# Description:	   Controls the ftpd server.
### END INIT INFO
# GPL Licensed

# Source function library
. /lib/lsb/init-functions

DAEMON="$FTPDROOT/sbin/proftpd"
PIDFILE="$FTPDPID"
FTPDLOG="/var/log/ftpd.log"
FTPDCONFIG="$FTPDCONFIG"
USER="$FTPDUSER"
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
PROCESSNAME="proftpd"
DESC="FTP Server"

os="$os"

if [ "\$os" = "centos" ]
then
	# source function library
	. /etc/rc.d/init.d/functions
fi

# Does the executable exist?
if [ ! -x "\$DAEMON" ]; then echo "could not locate \$DAEMON - exiting." ; exit 0; fi

# Get the pid file
if [ -f "\$PIDFILE" ]; then
	PIDN="\`cat \"\$PIDFILE\" 2> /dev/null\`"
fi

start_ftpd()
{
	# Start based on OS type
	if [ "\$os" = "centos" ]
	then 	
		if \$DAEMON
 		then
						echo " ${cc_green}OK${cc_normal}"
				else
						echo -n " ${cc_red}FAIL${cc_normal} ("

						if [ ! -z "\$PIDN" ] && killall -0 \$PROCESSNAME 2> /dev/null
						then
								echo -n "${cc_yellow}Seems \$PROCESSNAME is already running.${cc_normal}"

								# and just to be sure the pids are not out of whack
								killall -2 \$PROCESSNAME 2> /dev/null
						else
								echo -n "${cc_yellow}Looks like \$PROCESSNAME is not already running.${cc_normal}"
						fi
			echo -n ")"

						exit 1
				fi
	elif [ "\$os" = "debian" ] || [ "\$os" = "ubuntu" ]
	then
		if  start-stop-daemon --start --quiet --oknodo --pidfile "\$PIDFILE" --exec "\$DAEMON" 
		then
						echo " ${cc_green}OK${cc_normal}"
				else
						echo " ${cc_red}FAIL${cc_normal} (is it already running?)"
						exit 1
				fi

	fi
}

stop_ftpd()
{

	# Stop  based on OS
	if [ "\$os" = "centos" ]
	then 
		if [ ! -z "\$PIDN" ] && killall -0 \$PROCESSNAME 2> /dev/null
		then
			if killall -2 \$PROCESSNAME 2> /dev/null
			then
				echo " ${cc_green}OK${cc_normal}"
			else
				echo " ${cc_red}FAIL${cc_normal}"
			fi
		else
			echo -n " ${cc_red}FAIL${cc_normal}"
			echo " ${cc_yellow}Looks like \$PROCESSNAME is not running.${cc_normal}"						
		fi
	elif [ "\$os" = "debian" ] || [ "\$os" = "ubuntu" ]
	then
		if start-stop-daemon --stop --quiet --pidfile \$PIDFILE --retry 10 --exec \$DAEMON 2> /dev/null
		then
			echo " ${cc_green}OK${cc_normal}"

			# and just to be sure the pids are not out of whack
			killall -2 \$PROCESSNAME 2> /dev/null
		else
			echo -n " ${cc_cyan}FAIL${cc_normal} ("

 			if [ ! -z "\$PIDN" ] && killall -0 \$PROCESSNAME 2> /dev/null
	 		then
				echo -n "${cc_yellow}Seems \$PROCESSNAME is running but not as pid '\$PIDN' we were expecting. Killing all.${cc_normal}"

				# and just to be sure the pids are not out of whack
				killall -2 \$PROCESSNAME 2> /dev/null
			else
				echo -n "${cc_yellow}Looks like \$PROCESSNAME is not running.${cc_normal}"
			fi

			echo ")"
		fi

	fi

	# 5 seconds grace
	sleep 5

		# And finally, to ensure there are no issues
		killall -9 \$PROCESSNAME 2> /dev/null

	rm -f "\$PIDFILE"
	return 0
}

reload_ftpd()
{
	if [ ! -z "\$PIDN" ] && kill -0 \$PIDN 2> /dev/null; then
		kill -HUP \$PIDN >/dev/null 2>&1 || return 1
		return 0
	else
		echo "Error: ftpd is not running."
		return 1
	fi
}

case "\$1" in
  start)
	echo -n "Starting \$DESC (\$PROCESSNAME): "
	start_ftpd
	;;
  stop)
	echo -n "Stopping \$DESC (\$PROCESSNAME): "
	stop_ftpd 
	;;
  force-reload|reload)
	echo -n "Reloading \$DESC (\$PROCESSNAME): "
	reload_ftpd 
	;;
  restart)
	echo "Restarting \$DESC (\$PROCESSNAME): "
	\$0 stop
	sleep 2s
	\$0 start
	;;
  cron)
	start_ircd || echo "Ftpd not running, starting it"
	;;

  *)
	echo "Usage: \$0 {start|stop|restart|reload|force-reload|cron}"
	exit 1
esac
EOF

		# Set set permissions on the startup script
		chmod +x /etc/init.d/$FTPDUSER-server 2> /dev/null
		chown root.root /etc/init.d/$FTPDUSER-server 2> /dev/null
	
		# ---- INSTALL CONTROL SCRIPTS -- END ----

		# ---- INSTALL CONFIG -- START --
		cat > $FTPDCONFIG << EOF
ServerName					  "ThumbWhere FTP"
ServerType					  standalone
DefaultServer				   on
Port							21
UseIPv6						 off
Umask						   022
MaxInstances					30
User							tw-ftpd
Group						   thumbwhere
DefaultRoot					 ~
AllowOverwrite				  on
<Limit SITE_CHMOD>
  DenyAll
</Limit>
EOF

	fi

	# ---- INSTALL CONFIG -- END --

	echo " - Setting permissions"
	chown -R $FTPDUSER.$GROUP $HOMEROOT/$FTPDUSER/ 2> /dev/null

	# Enable or disable...
	enable_disable $FTPDUSER $FTPD_ROLE

fi

#########################################################################################
#
# Install MYSQLD
#

if [ "$MYSQLD_ROLE" != "" ]
then
	echo "*** ${cc_cyan}Installing MYSQLD ($MYSQLDFOLDER)${cc_normal}"
	
	create_user_and_stop_service $MYSQLDUSER $MYSQLDPROCESS

	if [[ $MYSQLD_ROLE = *compile* ]]
	then
		cp $DOWNLOADS/$MYSQLDFILE $HOMEROOT/$MYSQLDUSER/
		chown $MYSQLDUSER.$GROUP $HOMEROOT/$MYSQLDUSER
		cd  $HOMEROOT/$MYSQLDUSER
		echo " - Deleting old instance"
		rm -rf $MYSQLDFOLDER
		echo " - Uncompressing"
		tar -xzf $MYSQLDFILE
		echo " - Building"
		cd $MYSQLDFOLDER

		# Start with all the correct owners...
		chown -R $MYSQLDUSER .
		chgrp -R thumbwhere .		
		
		# make
		cmake . -DCMAKE_INSTALL_PREFIX=$MYSQLDROOT -DMYSQL_DATADIR=$MYSQLDDATAROOT
		make
		
	fi

	if [[ $MYSQLD_ROLE = *install* ]]
		then
		echo " - Installing"
		
		# This will install it into $MYSQLDROOT
 		cd $HOMEROOT/$MYSQLDUSER
		cd $MYSQLDFOLDER
		make install
		
		# End of source-build specific instructions
		# Postinstallation setup
		cd $MYSQLDROOT
		chown -R $MYSQLDUSER .
		chgrp -R thumbwhere .
		
		rm -rf $MYSQLDDATAROOT
				
		# Now finish install
		scripts/mysql_install_db --user=$MYSQLDUSER  --basedir=$MYSQLDROOT  --datadir=$MYSQLDDATAROOT --no-defaults
	

		echo "starting"
	
		# Start it safely
		bin/mysqld_safe --no-defaults --user=$MYSQLDUSER --basedir=$MYSQLDROOT  --datadir=$MYSQLDDATAROOT --pid-file=$MYSQLDPID --socket=$MYSQLDSOCKET &


		echo "sleeping for 5 seconds to ensure mysqld is started"
		
		sleep 5
		
		echo "setting password"
		
		# Set passwords
		bin/mysqladmin -u root password $MYSQLDPASSWORD --socket=$MYSQLDSOCKET

		echo "stopping"
	
		# Stop it...
		bin/mysqladmin --user=root --password=$MYSQLDPASSWORD shutdown --socket=$MYSQLDSOCKET
		
		# bin/mysqladmin -u root -h localhost password 'new-password'
		
		#chown -R root .
		#chown -R $MYSQLDUSER data
		# Next command is optional
		#cp support-files/my-medium.cnf /etc/my.cnf
		#bin/mysqld_safe --user=$MYSQLDUSER &
		# Next command is optional
		#cp support-files/mysql.server /etc/init.d/mysql.server		

		# Previous install
		#./configure  --prefix=$MYSQLDROOT  --enable-ctrls
		
	fi


	if [[ $MYSQLD_ROLE = *configure* ]]
	then

		echo " - Configuring"

		# ---- INSTALL CONTROL SCRIPTS -- START ----

		echo " - Creating control script."
		cat > /etc/init.d/$MYSQLDUSER-server << EOF
#!/bin/sh
### BEGIN INIT INFO
# Provides:	  $MYSQLDUSER-server
# Required-Start:	\$network \$syslog \$time
# Required-Stop:	 \$syslog
# Should-Start:	  \$local_fs
# Should-Stop:	   \$local_fs
# Default-Start:	 2 3 4 5
# Default-Stop:	  0 1 6
# Short-Description: Controls the mysqld server
# Description:	   Controls the mysqld server.
### END INIT INFO
# GPL Licensed

# Source function library
. /lib/lsb/init-functions

DAEMON="$MYSQLDROOT/bin/mysqld"
DAEMONSTARTOPTS="--no-defaults --user=$MYSQLDUSER --basedir=$MYSQLDROOT  --datadir=$MYSQLDDATAROOT --pid-file=$MYSQLDPID --socket=$MYSQLDSOCKET "
DAEMONSTOPOPTS="--no-defaults --user=$MYSQLDUSER --basedir=$MYSQLDROOT  --datadir=$MYSQLDDATAROOT --pid-file=$MYSQLDPID --socket=$MYSQLDSOCKET "
PIDFILE="$MYSQLDPID"
MYSQLDLOG="/var/log/mysqld.log"
MYSQLDCONFIG="$MYSQLDCONFIG"
USER="$MYSQLDUSER"
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
PROCESSNAME="mysqld"
DESC="MYSQL Server"

os="$os"

if [ "\$os" = "centos" ]
then
	# source function library
	. /etc/rc.d/init.d/functions
fi

# Does the executable exist?
if [ ! -x "\$DAEMON" ]; then echo "could not locate \$DAEMON - exiting." ; exit 0; fi

# Get the pid file
if [ -f "\$PIDFILE" ]; then
	PIDN="\`cat \"\$PIDFILE\" 2> /dev/null\`"
fi

start_mysqld()
{

	# Start based on OS type
	if [ "\$os" = "centos" ]
	then 	
		if \$DAEMON \$DAEMONSTARTOPTS
 		then
			echo " ${cc_green}OK${cc_normal}"
			else
				echo -n " ${cc_red}FAIL${cc_normal} ("

				if [ ! -z "\$PIDN" ] && killall -0 \$PROCESSNAME 2> /dev/null
				then
					echo -n "${cc_yellow}Seems \$PROCESSNAME is already running.${cc_normal}"

					# and just to be sure the pids are not out of whack
					killall -2 \$PROCESSNAME 2> /dev/null
				else
					echo -n "${cc_yellow}Looks like \$PROCESSNAME is not already running.${cc_normal}"
				fi
		echo -n ")"
		exit 1
	fi
	elif [ "\$os" = "debian" ] || [ "\$os" = "ubuntu" ]
	then
		if  start-stop-daemon --start --quiet --chuid \$USER -b --pidfile "\$PIDFILE" --exec "\$DAEMON" -- \$DAEMONSTARTOPTS 
		then
			echo " ${cc_green}OK${cc_normal}"
		else
			echo " ${cc_red}FAIL${cc_normal} (is it already running?)"
			exit 1
		fi

	fi
	
	
	
	# Wait till it is running...
	RUNNING="\`/home/tw-mysqld/mysqld/bin/mysqladmin --user=root --password=new-password --socket=/home/tw-mysqld/mysqld.sock status  2> /dev/null\`"

	while [[ \$RUNNING != *Uptime* ]]
	do
			echo Waiting till \$PROCESSNAME is running and answering requests.	
			sleep 1
			RUNNING="\`$MYSQLDROOT/bin/mysqladmin --user=root --password=$MYSQLDPASSWORD --socket=$MYSQLDSOCKET status  2> /dev/null\`"
	done
	echo \$PROCESSNAME is running and answering requests.
	
}

stop_mysqld()
{

	# Stop  based on OS
	if [ "\$os" = "centos" ]
	then 
		if [ ! -z "\$PIDN" ] && killall -0 \$PROCESSNAME 2> /dev/null
		then
			if killall -2 \$PROCESSNAME 2> /dev/null
			then
				echo " ${cc_green}OK${cc_normal}"
			else
				echo " ${cc_red}FAIL${cc_normal}"
			fi
		else
			echo -n " ${cc_red}FAIL${cc_normal}"
			echo " ${cc_yellow}Looks like \$PROCESSNAME is not running.${cc_normal}"						
		fi
	elif [ "\$os" = "debian" ] || [ "\$os" = "ubuntu" ]
	then
		if start-stop-daemon --stop --quiet --pidfile \$PIDFILE --retry 10 --exec \$DAEMON -- \$DAEMONSTOPOPTS 2> /dev/null
		then
			echo " ${cc_green}OK${cc_normal}"

			# and just to be sure the pids are not out of whack
			killall -2 \$PROCESSNAME 2> /dev/null
		else
			echo -n " ${cc_cyan}FAIL${cc_normal} ("

 			if [ ! -z "\$PIDN" ] && killall -0 \$PROCESSNAME 2> /dev/null
	 		then
				echo -n "${cc_yellow}Seems \$PROCESSNAME is running but not as pid '\$PIDN' we were expecting. Killing all.${cc_normal}"

				# and just to be sure the pids are not out of whack
				killall -2 \$PROCESSNAME 2> /dev/null
			else
				echo -n "${cc_yellow}Looks like \$PROCESSNAME is not running.${cc_normal}"
			fi

			echo ")"
		fi

	fi

	# 5 seconds grace
	# sleep 5

	# And finally, to ensure there are no issues
	killall -9 \$PROCESSNAME 2> /dev/null

	rm -f "\$PIDFILE"
	return 0
}

reload_mysqld()
{
	if [ ! -z "\$PIDN" ] && kill -0 \$PIDN 2> /dev/null; then
		kill -HUP \$PIDN >/dev/null 2>&1 || return 1
		return 0
	else
		echo "Error: mysqld is not running."
		return 1
	fi
}

case "\$1" in
  start)
	echo -n "Starting \$DESC (\$PROCESSNAME): "
	start_mysqld
	;;
  stop)
	echo -n "Stopping \$DESC (\$PROCESSNAME): "
	stop_mysqld 
	;;
  force-reload|reload)
	echo -n "Reloading \$DESC (\$PROCESSNAME): "
	reload_mysqld 
	;;
  restart)
	echo "Restarting \$DESC (\$PROCESSNAME): "
	\$0 stop
	sleep 2s
	\$0 start
	;;
  cron)
	start_ircd || echo "Ftpd not running, starting it"
	;;

  *)
	echo "Usage: \$0 {start|stop|restart|reload|force-reload|cron}"
	exit 1
esac
EOF

		# Set set permissions on the startup script
		chmod +x /etc/init.d/$MYSQLDUSER-server 2> /dev/null
		chown root.root /etc/init.d/$MYSQLDUSER-server 2> /dev/null
	
		# ---- INSTALL CONTROL SCRIPTS -- END ----

		# ---- INSTALL CONFIG -- START --
		cat > $MYSQLDCONFIG << EOF
[client]
port            = 3306
socket          = $MYSQLDSOCKET

[mysqld]
port            = 3306
socket          = $MYSQLDSOCKET
skip-external-locking
key_buffer_size = 16M
max_allowed_packet = 1M
table_open_cache = 64
sort_buffer_size = 512K
net_buffer_length = 8K
read_buffer_size = 256K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M
log-bin=mysql-bin
binlog_format=mixed
server-id       = 1

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout
EOF

	fi

	# ---- INSTALL CONFIG -- END --

	echo " - Setting permissions"
	chown -R $MYSQLDUSER.$GROUP $HOMEROOT/$MYSQLDUSER/ 2> /dev/null

	# Enable or disable...
	enable_disable $MYSQLDUSER $MYSQLD_ROLE

fi


#########################################################################################
#
# Install PHP
#

if [ "$PHP_ROLE" != "" ]
then
	echo "*** ${cc_cyan}Installing PHP ($PHPFOLDER)${cc_normal}"
	
	create_user $PHPUSER

	if [[ $PHP_ROLE = *compile* ]]
	then
		cp $DOWNLOADS/$PHPFILE $HOMEROOT/$PHPUSER/
		chown $PHPUSER.$GROUP $HOMEROOT/$PHPUSER
		cd  $HOMEROOT/$PHPUSER
		echo " - Deleting old instance"
		rm -rf $PHPFOLDER
		echo " - Uncompressing"
		tar -xzf $PHPFILE
		echo " - Building"
		cd $PHPFOLDER

		# Start with all the correct owners...
		chown -R $PHPUSER .
		chgrp -R thumbwhere .		

		./configure --prefix=$PHPROOT --with-apxs2=$HTTPDROOT/bin/apxs --with-config-file-path=$PHPROOT --with-pdo-mysql --with-mysql --with-mysql-sock=$MYSQLDSOCKET --with-pear --enable-cli --with-curl --disable-cgi --with-zlib --with-gettext --with-gdbm --with-gd --enable-mbstring
		make
		
		# pdo
		#cd ext/pdo
		#$PHPROOT/bin/phpize
		#./configure  --with-php-config=$PHPROOT/bin/php-config
		#make
		#make install
		#cd ../..

		# pdo_mysql
		#cd ext/pdo_mysql
		#$PHPROOT/bin/phpize
		#./configure  --with-php-config=$PHPROOT/bin/php-config
		#make
		#make install		
		#cd ../..
		
		# restart httpd
		 /etc/init.d/tw-httpd-server restart
		 
		 
		
	fi

	if [[ $PHP_ROLE = *install* ]]
		then
		echo " - Installing"
		
		# This will install it into $PHPROOT
 		cd $HOMEROOT/$PHPUSER
		cd $PHPFOLDER
		
		make install
		
		/etc/init.d/tw-httpd-server restart
	fi

	if [[ $PHP_ROLE = *configure* ]]
	then

		echo " - Configuring"
		
		cd  $HOMEROOT/$PHPUSER/$PHPFOLDER
					
		cp php.ini-production $PHPROOT/php.ini

		# ---- INSTALL CONFIG -- START --
		cat > $PHPCONFIG << EOF
Some config..
EOF

	fi

	# ---- INSTALL CONFIG -- END --

fi



#
# And we are done..
#

echo " *** ${cc_cyan}Completed${cc_normal}"
echo ""
