###############################################################################
#
# This will setup ThumbWhere Fabric node on a Linux Box
#
# Although this script can be run manually, in will generally
# be executed as part of an automated install.

# We want the script to fail on any errors... so..
set -e

###############################################################################
#
# Config variables
#

IRCD_TASK=""
REDIS_TASK="download,compile,install,configure"
NODEJS_TASK=""
VARNISH_TASK=""
HTTPD_TASK=""
FTPD_TASK=""

IRCDURL=http://downloads.sourceforge.net/project/inspircd/InspIRCd-2.0/2.0.2/InspIRCd-2.0.2.tar.bz2
REDISURL=http://redis.googlecode.com/files/redis-2.4.6.tar.gz
NODEJSURL=http://nodejs.org/dist/v0.6.8/node-v0.6.8.tar.gz
VARNISHURL=http://repo.varnish-cache.org/source/varnish-3.0.2.tar.gz
HTTPDURL=http://apache.mirror.aussiehq.net.au//httpd/httpd-2.2.21.tar.gz
FTPDURL=ftp://ftp.proftpd.org/distrib/source/proftpd-1.3.4a.tar.gz

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
HTTPDUSER=tw-httpd
FTPDUSER=tw-ftpd

IRCDFILE=`echo $IRCDURL | rev | cut -d\/ -f1 | rev`
REDISFILE=`echo $REDISURL | rev | cut -d\/ -f1 | rev`
NODEJSFILE=`echo $NODEJSURL | rev | cut -d\/ -f1 | rev`
VARNISHFILE=`echo $VARNISHURL | rev | cut -d\/ -f1 | rev`
HTTPDFILE=`echo $HTTPDURL | rev | cut -d\/ -f1 | rev`
FTPDFILE=`echo $FTPDURL | rev | cut -d\/ -f1 | rev`

IRCDFOLDER=`echo $IRCDFILE | rev | cut -d\. -f3- | rev`
REDISFOLDER=`echo $REDISFILE | rev | cut -d\. -f3- | rev`
NODEJSFOLDER=`echo $NODEJSFILE | rev | cut -d\. -f3- | rev`
VARNISHFOLDER=`echo $VARNISHFILE | rev | cut -d\. -f3- | rev`
HTTPDFOLDER=`echo $HTTPDFILE | rev | cut -d\. -f3- | rev`
FTPDFOLDER=`echo $FTPDFILE | rev | cut -d\. -f3- | rev`

IRCDPROCESS=inspircd
IRCDCONFIG=/etc/inspircd/inspircd.conf
IRCDPID=$HOMEROOT/$IRCDUSER/inspircd.pid

REDISCONFIG=$HOMEROOT/$REDISUSER/redis.conf
REDISLOGS=$HOMEROOT/$REDISUSER
REDISPID=$HOMEROOT/$REDISUSER/redis.pid
REDISPROCESS=redis

VARNISHCONFIG=$HOMEROOT/$VARNISHUSER/thumbwhere.vcl
VARNISHPROCESS=varnishd

HTTPDROOT=$HOMEROOT/$HTTPDUSER/apache2
HTTPDCONFIG=$HTTPDROOT/conf/httpd.conf
HTTPDPID=$HOMEROOT/$HTTPDUSER/httpd.pid
HTTPDPROCESS=httpd

FTPDROOT=$HOMEROOT/$FTPDUSER/ftpd
FTPDCONFIG=$FTPDROOT/etc/proftpd.conf
FTPDPID=$FTPDROOT/var/proftpd.pid
FTPDPROCESS=proftpd

echo "adding group"
groupadd -f thumbwhere

#
# Install the tools we will need
#

os=""

echo "`grep centos /proc/version -c`"

if [ "`grep centos /proc/version -c`" != "0" ] 
then
	os="centos"
fi

echo  "`grep debian /proc/version -c`"

if [ "`grep debian /proc/version -c`" != "0" ] 
then
	os="debian"
fi

if [ $os = "" ] 
then
	echo "not a valid system os"
	exit 1
fi

if [ $os == "debian" ]
then
	apt-get -y install wget bzip2 binutils g++ make tcl8.5 curl build-essential openssl libssl-dev libssh-dev pkg-config libpcre3 libpcre3-dev libpcre++0 xsltproc libncurses5-dev
elif [ $os == "centos" ]
then
        yum -y install wget bzip2 binutils gcc-c++ make gcc tcl curl openssl pcre gnutls openssh openssl ncurses pcre-devel gnutls-devel openssl-devel ncurses-devel libxslt redhat-lsb
fi

#
# Install the source packages...
#

echo "*** Downloading source packages"

mkdir -p $DOWNLOADS
cd $DOWNLOADS

if [[ $IRCD_TASK == *download* ]] 
then
	[ -f $IRCDFILE ] && echo "$IRCDFILE exists" || wget $IRCDURL
fi

if [[ $REDIS_TASK == *download* ]] 
then
	[ -f $REDISFILE ] && echo "$REDISFILE exists" || wget $REDISURL
fi

if [[ $NODEJS_TASK == *download* ]] 
then
	[ -f $NODEJSFILE ] && echo "$NODEJSFILE exists" || wget $NODEJSURL
fi

if [[ $VARNISH_TASK == *download* ]] 
then
	[ -f $VARNISHFILE ] && echo "$VARNISHFILE exists" || wget $VARNISHURL
fi

if [[ $HTTPD_TASK == *download* ]] 
then
	[ -f $HTTPDFILE ] && echo "$HTTPDFILE exists" || wget $HTTPDURL
fi

if [[ $FTPD_TASK == *download* ]] 
then
	[ -f $FTPDFILE ] && echo "$FTPDFILE exists" || wget $FTPDURL
fi

cd ..

###############################################################################
#
# Install IRCD
# 

if [ "$IRCD_TASK" != "" ]
then
	echo "*** Installing IRCD ($IRCDFOLDER)"

	if [ "`id -un $IRCDUSER`" != "$IRCDUSER" ]
	then
		 echo " - Adding user $IRCDUSER"
		useradd $IRCDUSER -m -g $GROUP
	else
		if [ -f /etc/init.d/$IRCDUSER-server ]
		then
		 	echo " - Stopping service"
			/etc/init.d/$IRCDUSER-server stop
		else
		 	echo " - Killing service (control script not found at /etc/init.d/$IRCDUSER-server)"
			for i in `ps ax | grep inspircd | grep -v grep | cut -d ' ' -f 1`
			do
  				kill -2 $i
			done
		fi
	fi

	if [[ $IRCD_TASK == *compile* ]]
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
		echo " - Installing"
		make install
	fi

	#
	# Generate configure scripts
	#
	
	if [[ $IRCD_TASK == *configure* ]]
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
# Required-Start:    \$network \$syslog \$time
# Required-Stop:     \$syslog
# Should-Start:      \$local_fs
# Should-Stop:       \$local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Controls the ircd server
# Description:       Controls the ircd server.
### END INIT INFO
# GPL Licensed

# Source function library
. /lib/lsb/init-functions

if [ "\$os" == "centos" ]
then
# source function library
. /etc/rc.d/init.d/functions
fi


os=""
if [ "\`grep centos /proc/version -c\`" != "0" ]
then
        os="centos"
fi
if [ "\`grep debian /proc/version -c\`" != "0" ]
then
        os="debian"
fi
if [ "\$os" == "" ]
then
        echo "not a valid system os"
        exit 1
fi

if [ "\$os" == "centos" ]
then
# source function library
. /etc/rc.d/init.d/functions
fi



IRCD="/usr/sbin/inspircd"
IRCDPID="$IRCDPID"
IRCDLOG="/var/log/inspircd.log"
IRCDCONFIG="$IRCDCONFIG"
IRCDARGS="--logfile \$IRCDLOG --config \$IRCDCONFIG"
USER="$IRCDUSER"
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
SERVICENAME=$IRCDUSER-service
PROCESSNAME=$IRCDPROCESS

#if [ -f "/var/lib/inspircd/inspircd" ]; then
#	. /var/lib/inspircd/inspircd
#fi

if [ ! -x "\$IRCD" ]; then exit 0; fi

if [ -f "\$IRCDPID" ]; then
	IRCDPIDN="\`cat \"\$IRCDPID\" 2> /dev/null\`"
fi

start_ircd()
{
	[ -f "\$IRCDPID" ] || ( touch "\$IRCDPID" ; chown "\$USER" "\$IRCDPID" )
	[ -f "\$IRCDLOG" ] || ( touch "\$IRCDLOG" ; chown "\$USER:thumbwhere" "\$IRCDLOG" ; chmod 0640 "\$IRCDLOG" )
	export LD_LIBRARY_PATH=/usr/lib/inspircd
	
	# Start based on OS type
	if [ "\$os" == "centos" ]
	then 	
		exec su - \$USER -c "\$IRCD \$IRCDARGS"
	elif [ "\$os" == "debian" ]
	then
		start-stop-daemon --start --quiet --oknodo --chuid "\$USER" --pidfile "\$IRCDPID" --exec "\$IRCD" --  \$IRCDARGS
	fi
}

stop_ircd()
{

	# This logic is generated at script built time (if you are wondering about this comparison)
	if [ "\$os" == "centos" ]
	then 	
		killproc \$PROCESSNAME -TERM
	elif [ "\$os" == "debian" ]
	then
		start-stop-daemon --stop --quiet --pidfile "\$IRCDPID" 
	fi
	
	rm -f "\$IRCDPID"
	return 0
}

reload_ircd()
{
	if [ ! -z "\$IRCDPIDN" ] && kill -0 \$IRCDPIDN 2> /dev/null; then
		kill -HUP \$IRCDPIDN >/dev/null 2>&1 || return 1
		return 0
	else
		echo "Error: IRCD is not running."
		return 1
	fi
}

case "\$1" in
  start)
	#if [ "\$INSPIRCD_ENABLED" != "1" ]; then
	#	echo "Please configure inspircd first and edit /etc/default/inspircd, otherwise inspircd won't start"
	#	exit 0
	#fi
	echo "Starting Inspircd... "
	start_ircd && echo "... done."
	;;
  stop)
	echo "Stopping Inspircd... "
	stop_ircd && echo "... done."
	;;
  force-reload|reload)
	echo "Reloading Inspircd... "
	reload_ircd && echo "... done."
	;;
  restart)
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

		#
		# .. the rest of the configure scripts
		#
		

		chmod +x /etc/init.d/$IRCDUSER-server
		chown root.root /etc/init.d/$IRCDUSER-server
		if [ $os == "debian" ]
		then
			insserv /etc/init.d/$IRCDUSER-server
		elif [ $os == "centos" ]
		then
			chkconfig $IRCDUSER-server on
		else
			ln -fs /etc/init.d/$IRCDUSER-server /etc/rc2.d/S19$IRCDUSER-server
		fi
	
	fi

# ---- IRCD CONTROL SCRIPT --- END ---

	echo " - Setting permissions"
	chown -R $IRCDUSER.$GROUP $HOMEROOT/$IRCDUSER/

	echo " - Starting service"
	/etc/init.d/$IRCDUSER-server start

fi


###############################################################################
#
# Install Redis
#

if [ $REDIS_TASK == 'true' ]
then
	echo "*** Installing REDIS ($REDISFILE)"
	if [ "`id -un $REDISUSER`" != "$REDISUSER" ]
	then
		 echo " - Adding user $REDISUSER"
		useradd $REDISUSER -m -g $GROUP
	else
		if [ -f /etc/init.d/$REDISUSER-server ]
		then
		 	echo " - Stopping service"
			/etc/init.d/$REDISUSER-server stop
		else
			echo " - Killing service (control script not found at /etc/init.d/$REDISUSER-server)"
			for i in `ps ax | grep redis-server | grep -v grep | cut -d ' ' -f 1`
			do
				kill -2 $i
			done

		fi
	fi
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
	echo " - Testing"
	make test
	echo " - Installing"
	make install

	# 
	# Generate configure scripts
	#	

	echo " - Configuring"

# --- REDIS CONTROL SCRIPT -- START ----
	
	cat > /etc/init.d/$REDISUSER-server << EOF
#! /bin/sh
### BEGIN INIT INFO
# Provides:	     $REDISUSER-server
# Required-Start:       $syslog $remote_fs
# Required-Stop:	$syslog $remote_fs
# Should-Start:	 $local_fs
# Should-Stop:	  $local_fs
# Default-Start:	2 3 4 5
# Default-Stop:	 0 1 6
# Short-Description:    $REDISUSER-server - Persistent key-value db for ThumbWhere
# Description:	  $REDISUSER-server - Persistent key-value db for ThumbWhere
### END INIT INFO

# Source function library
. /lib/lsb/init-functions

if [ "\$os" == "centos" ]
then
# source function library
. /etc/rc.d/init.d/functions
fi


PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/local/bin/redis-server
DAEMON_ARGS=$REDISCONFIG
USER=\$REDISUSER
NAME=redis-server
DESC=redis-server
PIDFILE=$REDISPID

test -x \$DAEMON || exit 0
test -x \$DAEMONBOOTSTRAP || exit 0

set -e

case "\$1" in
  start)
	echo "Starting \$DESC: "
	touch \$PIDFILE
	chown $REDISUSER:$GROUP \$PIDFILE
	
	
	# Start based on OS type
	if [ "\$os" == "centos" ]
	then 	
		exec su - \$USER -c "\$DAEMON \$DAEMON_ARGS"
	elif [ "\$os" == "debian" ]
	then	
		start-stop-daemon --start --quiet --umask 007 --pidfile \$PIDFILE --chuid $REDISUSER:$GROUP --exec \$DAEMON -- \$DAEMON_ARGS
	fi
	;;
  stop)
	echo "Stopping \$DESC: "
	
	if [ "\$os" == "centos" ]
	then 	
		killproc \$DAEMON -TERM
	elif [ "\$os" == "debian" ]
	then
		start-stop-daemon --stop --retry 10 --quiet --oknodo --pidfile \$PIDFILE --exec \$DAEMON
	fi
	rm -f \$PIDFILE
	;;

  restart|force-reload)
	\${0} stop
	\${0} start
	;;
  *)
	echo "Usage: /etc/init.d/\$NAME {start|stop|restart|force-reload}" >&2
	exit 1
	;;
esac

exit 0
EOF

chmod +x /etc/init.d/$REDISUSER-server
chown root.root /etc/init.d/$REDISUSER-server
if [ $os == "debian" ]
then
	insserv /etc/init.d/$REDISUSER-server
elif [ $os == "centos" ]
then
        chkconfig $REDISUSER-server on
else
	ln -fs /etc/init.d/$REDISUSER-server /etc/rc2.d/S19$REDISUSER-server 
fi

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

	echo " - Setting permissions"

	chown -R $REDISUSER.$GROUP $HOMEROOT/$REDISUSER/

	echo " - Starting service"
	/etc/init.d/$REDISUSER-server start
fi

###############################################################################
#
# Install NODEJS
#

if [ $NODEJS_TASK == 'true' ]
then
	echo "*** Installing NODEJS ($NODEJSFOLDER)"

	if [ "`id -un $NODEJSUSER`" != "$NODEJSUSER" ]
	then
		echo " - Adding user $NODEJSUSER"
		useradd $NODEJSUSER -m -g $GROUP
	fi

	cp $DOWNLOADS/$NODEJSFILE $HOMEROOT/$NODEJSUSER/
	chown $NODEJSUSER.$GROUP $HOMEROOT/$NODEJSUSER
	cd  $HOMEROOT/$NODEJSUSER
	echo " - Deleting old instance"
	rm -rf $NODEJSFOLDER
	echo " - Uncompressing"
	tar -xzf $NODEJSFILE
	echo " - Building"
	cd $NODEJSFOLDER
	./configure --shared-zlib --shared-cares
	make
	#echo " - Testing"
	#make test
	echo " - Installing"
	make install
	echo " - Configuring"

	echo " - Setting permissions"
	chown -R $NODEJSUSER.$GROUP $HOMEROOT/$NODEJSUSER/

fi

###############################################################################
#
# Install VARNISH
#

if [ $VARNISH_TASK == 'true' ]
then
	echo "*** Installing VARNISH ($VARNISHFOLDER)"

	if [ "`id -un $VARNISHUSER`" != "$VARNISHUSER" ]
	then
		echo " - Adding user $VARNISHUSER"
		useradd $VARNISHUSER -m -g $GROUP
	else

		if [ -f /etc/init.d/$REDISUSER-server ]
		then
			echo " - Starting service"
			/etc/init.d/$VARNISHUSER-server stop
		else
			echo " - Killing service (control script not found at /etc/init.d/$VARNISHUSER-server)"
			for i in `ps ax | grep varnishd | grep -v grep | cut -d ' ' -f 1`
			do
				kill -2 $i
			done

		fi
	fi

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
	echo " - Installing"
	make install

	echo " - Configuring"

# ---- VARNISH CONTROL SCRIPT -- START ----

	cat > /etc/init.d/$VARNISHUSER-server << EOF
#! /bin/sh

### BEGIN INIT INFO
# Provides:	  $VARNISHUSER-server
# Required-Start:    \$local_fs \$remote_fs \$network
# Required-Stop:     \$local_fs \$remote_fs \$network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start HTTP accelerator
# Description:       This script provides a server-side cache
#		    to be run in front of a httpd and should
#		    listen on port 80 on a properly configured
#		    system
### END INIT INFO

# Source function library
. /lib/lsb/init-functions

if [ "\$os" == "centos" ]
then
# source function library
. /etc/rc.d/init.d/functions
fi

NAME=varnishd
DESC="ThumbWhere HTTP accelerator (Varnish)"
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin/
DAEMON=/usr/local/sbin/varnishd
PIDFILE=/var/run/\$NAME.pid

test -x \$DAEMON || echo "Could not locate \$DAEMON" exit 0

# Open files (usually 1024, which is way too small for varnish)
ulimit -n \${NFILES:-131072}

# Maxiumum locked memory size for shared memory log
ulimit -l \${MEMLOCK:-82000}

DAEMON_OPTS="-f $VARNISHCONFIG"

# Ensure we have a PATH
export PATH="\${PATH:+\$PATH:}/usr/sbin:/usr/bin:/sbin:/bin"

start_varnishd() {
    log_daemon_msg "Starting \$DESC" "\$NAME"
    output=\$(/bin/tempfile -s.varnish)
    if start-stop-daemon --start --quiet --pidfile \${PIDFILE} --exec \${DAEMON} -- -P \${PIDFILE} \$DAEMON_OPTS > \${output} 2>&1; then
	log_end_msg 0
    else
	log_end_msg 1
	cat \$output
	exit 1
    fi
    rm \$output
}

disabled_varnishd() {
    log_daemon_msg "Not starting \$DESC" "\$NAME"
    log_progress_msg "disabled in /etc/default/varnish"
    log_end_msg 0
}

stop_varnishd() {
    log_daemon_msg "Stopping \$DESC" "\$NAME"
    if start-stop-daemon \
	--stop --quiet --pidfile \$PIDFILE --retry 10 \
	--exec \$DAEMON; then
	log_end_msg 0
    else
	log_end_msg 1
    fi
}

reload_varnishd() {
    log_daemon_msg "Reloading \$DESC" "\$NAME"
    if /usr/share/varnish/reload-vcl -q; then
	log_end_msg 0
    else
	log_end_msg 1
    fi
}

status_varnishd() {
    status_of_proc -p "\${PIDFILE}" "\${DAEMON}" "\${NAME}"
}

case "\$1" in
    start)
	start_varnishd
	;;
    stop)
	stop_varnishd
	;;
    reload)
	reload_varnishd
	;;
    status)
	status_varnishd
	;;
    restart|force-reload)
	\$0 stop
	\$0 start
	;;
    *)
	log_success_msg "Usage: \$0 {start|stop|restart|force-reload}"
	exit 1
	;;
esac

exit 0
EOF

# ---- VARNISH CONTROL SCRIPT -- END ----

# ---- VARNISH CONFIG -- START ----

cat > $VARNISHCONFIG << EOF
backend default {
	.host = "0.0.0.0";
	.port = "80";
}
EOF

# ---- VARNISH CONFIG -- END ----

chmod +x /etc/init.d/$VARNISHUSER-server
chown root.root /etc/init.d/$VARNISHUSER-server

if [ $os == "debian" ]
then
	insserv /etc/init.d/$VARNISHUSER-server
elif [ $os == "centos" ]
then
        chkconfig $VARNISHUSER-server on
else
	ln -fs /etc/init.d/$VARNISHUSER-server /etc/rc2.d/S19$VARNISHUSER-server
fi

# ---- VARNISH CONTROL SCRIPT -- END ----

	echo " - Setting permissions"
	chown -R $VARNISHUSER.$GROUP $HOMEROOT/$VARNISHUSER/

	echo " - Starting service"
	/etc/init.d/$VARNISHUSER-server start

fi

###############################################################################
#
# Install HTTPD
#

if [ $HTTPD_TASK == 'true' ]
then
	echo "*** Installing HTTPD ($HTTPDFOLDER)"

	if [ "`id -un $HTTPDUSER`" != "$HTTPDUSER" ]
	then
		 echo " - Adding user $HTTPDUSER"
		useradd $HTTPDUSER -m -g $GROUP
	else
		if [ -f /etc/init.d/$HTTPDUSER-server ]
		then
		 	echo " - Stopping service"
			/etc/init.d/$HTTPDUSER-server stop
		else
		 	echo " - Killing service (control script not found at /etc/init.d/$HTTPDUSER-server)"
			#for i in `ps ax | grep httpd | grep -v grep | cut -d ' ' -f 1`
			#do
  			#	kill -2 $i
			#done
		fi
	fi

	cp $DOWNLOADS/$HTTPDFILE $HOMEROOT/$HTTPDUSER/
	chown $HTTPDUSER.$GROUP $HOMEROOT/$HTTPDUSER/
	cd  $HOMEROOT/$HTTPDUSER
	echo " - Deleting old instance"
	rm -rf $HTTPDFOLDER
	echo " - Uncompressing"
	tar -xzf $HTTPDFILE
	echo " - Building"
	cd $HTTPDFOLDER
	./configure  --prefix=$HTTPDROOT
	make
	echo " - Installing"
	make install
	echo " - Configuring"

	# ---- INSTALL CONTROL SCRIPTS -- START ----

	cat > /etc/init.d/$HTTPDUSER-server << EOF
#!/bin/sh
### BEGIN INIT INFO
# Provides:	  $HTTPDUSER-server
# Required-Start:    \$network \$syslog \$time
# Required-Stop:     \$syslog
# Should-Start:      \$local_fs
# Should-Stop:       \$local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Controls the httpd server
# Description:       Controls the httpd server.
### END INIT INFO
# GPL Licensed

# Source function library
. /lib/lsb/init-functions

if [ "\$os" == "centos" ]
then
# source function library
. /etc/rc.d/init.d/functions
fi


HTTPD="$HTTPDROOT/bin/apache2ctrl"
HTTPDPID="$HTTPDPID"
HTTPDLOG="/var/log/inspircd.log"
HTTPDCONFIG="$IRCDCONFIG"
USER="$HTTPDUSER"
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin


if [ ! -x "\$HTTPD" ]; then exit 0; fi

if [ -f "\$HTTPDPID" ]; then
	HTTPDPIDN="\`cat \"\$HTTPDPID\" 2> /dev/null\`"
fi

start_httpd()
{
	start-stop-daemon --start --quiet --oknodo --chuid "\$USER" --pidfile "\$HTTPDPID" --exec "\$HTTPD" -- start
}

stop_httpd()
{
	start-stop-daemon --stop --quiet --pidfile "\$HTTPDPID" --exec "\$HTTPD" -- stop
	rm -f "\$HTTPDPID"
	return 0
}

reload_httpd()
{
	if [ ! -z "\$HTTPDPIDN" ] && kill -0 \$HTTPDPIDN 2> /dev/null; then
		kill -HUP \$HTTPDPIDN >/dev/null 2>&1 || return 1
		return 0
	else
		echo "Error: Apache2 is not running."
		return 1
	fi
}

case "\$1" in
  start)
	echo -n "Starting Apache2... "
	start_httpd && echo "done."
	;;
  stop)
	echo -n "Stopping Apache2... "
	stop_httpd && echo "done."
	;;
  force-reload|reload)
	echo -n "Reloading Apache2 config "
	reload_httpd && echo "done."
	;;
  restart)
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

if [ $os == "debian" ]
then
	insserv /etc/init.d/$HTTPDUSER-server
elif [ $os == "centos" ]
then
        chkconfig $HTTPDUSER-server on
else
	ln -fs /etc/init.d/$HTTPDUSER-server /etc/rc2.d/S19$HTTPDUSER-server
fi

	# ---- INSTALL CONTROL SCRIPTS -- END ----

	# ---- INSTALL CONFIG -- START --
	cat > $HTTPDCONFIG << EOF
ServerRoot "$HTTPDROOT"
Listen 127.0.0.1:81
User $HTTPDUSER
Group thumbwhere
ServerAdmin james@thumbwhere.com
ServerName apache.thumbwhere.com:80
DocumentRoot "$HTTPDROOT/htdocs"
<Directory />
    Options FollowSymLinks
    AllowOverride None
    Order deny,allow
    Deny from all
</Directory>
<Directory "$HTTPDROOT/htdocs">
    Options Indexes FollowSymLinks
    AllowOverride None
    Order allow,deny
    Allow from all
</Directory>
<IfModule dir_module>
    DirectoryIndex index.html
</IfModule>
<FilesMatch "^\.ht">
    Order allow,deny
    Deny from all
    Satisfy All
</FilesMatch>
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
<IfModule alias_module>
    ScriptAlias /cgi-bin/ "$HTTPDROOT/cgi-bin/"
</IfModule>
<Directory "$HTTPDROOT/cgi-bin">
    AllowOverride None
    Options None
    Order allow,deny
    Allow from all
</Directory>
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
EOF

	# ---- INSTALL CONFIG -- END --

	echo " - Setting permissions"
	chown -R $HTTPDUSER.$GROUP $HOMEROOT/$HTTPDUSER/

        echo " - Starting service"
        /etc/init.d/$HTTPDUSER-server start

fi

#
# Install FTPD
#

if [ $FTPD_TASK == 'true' ]
then
	echo "*** Installing FTPD ($FTPDFOLDER)"

	if [ "`id -un $FTPDUSER`" != "$FTPDUSER" ]
	then
		 echo " - Adding user $FTPDUSER"
		useradd $FTPDUSER -m -g $GROUP
	else
		if [ -f /etc/init.d/$FTPDUSER-server ]
		then
		 	echo " - Stopping service"
			/etc/init.d/$FTPDUSER-server stop
		else
		 	echo " - Killing service (control script not found at /etc/init.d/$FTPDUSER-server)"
			#for i in `ps ax | grep ftpd | grep -v grep | cut -d ' ' -f 1`
			#do
  			#	kill -2 $i
			#done
		fi
	fi

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
	echo " - Installing"
	make install
	echo " - Configuring"

	# ---- INSTALL CONTROL SCRIPTS -- START ----

	cat > /etc/init.d/$FTPDUSER-server << EOF
#!/bin/sh
### BEGIN INIT INFO
# Provides:	  $FTPDUSER-server
# Required-Start:    \$network \$syslog \$time
# Required-Stop:     \$syslog
# Should-Start:      \$local_fs
# Should-Stop:       \$local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Controls the ftpd server
# Description:       Controls the ftpd server.
### END INIT INFO
# GPL Licensed

# Source function library
. /lib/lsb/init-functions

if [ "\$os" == "centos" ]
then
# source function library
. /etc/rc.d/init.d/functions
fi

FTPD="$FTPDROOT/sbin/proftpd"
FTPDPID="$FTPDPID"
FTPDLOG="/var/log/ftpd.log"
FTPDCONFIG="$IRCDCONFIG"
USER="$FTPDUSER"
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin


if [ ! -x "\$FTPD" ]; then echo "could not locate \$FTPD - exiting" ; exit 0; fi

if [ -f "\$FTPDPID" ]; then
	FTPDPIDN="\`cat \"\$FTPDPID\" 2> /dev/null\`"
fi

start_ftpd()
{
	start-stop-daemon --start --quiet --oknodo --pidfile "\$FTPDPID" --exec "\$FTPD" 
}

stop_ftpd()
{
	start-stop-daemon --stop --quiet --pidfile "\$FTPDPID"
	rm -f "\$FTPDPID"
	return 0
}

reload_ftpd()
{
	if [ ! -z "\$FTPDPIDN" ] && kill -0 \$FTPDPIDN 2> /dev/null; then
		kill -HUP \$FTPDPIDN >/dev/null 2>&1 || return 1
		return 0
	else
		echo "Error: ftpd is not running."
		return 1
	fi
}

case "\$1" in
  start)
	echo -n "Starting ftpd... "
	start_ftpd && echo "done."
	;;
  stop)
	echo -n "Stopping ftpd... "
	stop_ftpd && echo "done."
	;;
  force-reload|reload)
	echo -n "Reloading ftpd config "
	reload_ftpd && echo "done."
	;;
  restart)
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

chmod +x /etc/init.d/$FTPDUSER-server
chown root.root /etc/init.d/$FTPDUSER-server
if [ $os == "debian" ]
then
	insserv /etc/init.d/$FTPDUSER-server
elif [ $os == "centos" ]
then
        chkconfig $FTPDUSER-server on
else
	ln -fs /etc/init.d/$FTPDUSER-server /etc/rc2.d/S19$FTPDUSER-server
fi
	# ---- INSTALL CONTROL SCRIPTS -- END ----

	# ---- INSTALL CONFIG -- START --
	cat > $FTPDCONFIG << EOF
ServerName                      "ThumbWhere FTP"
ServerType                      standalone
DefaultServer                   on
Port                            21
UseIPv6                         off
Umask                           022
MaxInstances                    30
User                            tw-ftpd
Group                           thumbwhere
DefaultRoot                     ~
AllowOverwrite                  on
<Limit SITE_CHMOD>
  DenyAll
</Limit>
EOF

	# ---- INSTALL CONFIG -- END --

	echo " - Setting permissions"
	chown -R $FTPDUSER.$GROUP $HOMEROOT/$FTPDUSER/

        echo " - Starting service"
        /etc/init.d/$FTPDUSER-server start
fi
