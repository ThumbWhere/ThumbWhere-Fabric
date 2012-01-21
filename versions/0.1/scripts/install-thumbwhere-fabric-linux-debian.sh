#######################################################
#
# This will setup ThumbWhere Fabric node on a Linux Box
#
# Although this script can be run manually, in will generally
# be executed as part of an automated install.

# We want the script to fail on any errors... so..
set -e

#
# Config variables
#

INSTALL_IRC=true
INSTALL_REDIS=false
INSTALL_NODEJS=false
INSTALL_VARNISH=false
INSTALL_HTTPD=false
INSTALL_FTPD=false

IRCURL=http://downloads.sourceforge.net/project/inspircd/InspIRCd-2.0/2.0.2/InspIRCd-2.0.2.tar.bz2
REDISURL=http://redis.googlecode.com/files/redis-2.4.6.tar.gz
NODEJSURL=http://nodejs.org/dist/v0.6.8/node-v0.6.8.tar.gz
VARNISHURL=http://repo.varnish-cache.org/source/varnish-3.0.2.tar.gz
HTTPDURL=http://apache.mirror.aussiehq.net.au//httpd/httpd-2.2.21.tar.gz
FTPDURL=ftp://ftp.proftpd.org/distrib/source/proftpd-1.3.4a.tar.gz


#
# Generate some more convenient variables based on our config.
#

DOWNLOADS=~/tw-downloads
HOMEROOT=/home

GROUP=thumbwhere
IRCUSER=tw-irc
REDISUSER=tw-redis
NODEJSUSER=tw-nodejs
VARNISHUSER=tw-varnish
HTTPDUSER=tw-httpd
FTPDUSER=tw-ftpd


IRCFILE=`echo $IRCURL | rev | cut -d\/ -f1 | rev`
REDISFILE=`echo $REDISURL | rev | cut -d\/ -f1 | rev`
NODEJSFILE=`echo $NODEJSURL | rev | cut -d\/ -f1 | rev`
VARNISHFILE=`echo $VARNISHURL | rev | cut -d\/ -f1 | rev`
HTTPDFILE=`echo $HTTPDURL | rev | cut -d\/ -f1 | rev`
FTPDFILE=`echo $FTPDURL | rev | cut -d\/ -f1 | rev`

IRCFOLDER=`echo $IRCFILE | rev | cut -d\. -f3- | rev`
REDISFOLDER=`echo $REDISFILE | rev | cut -d\. -f3- | rev`
NODEJSFOLDER=`echo $NODEJSFILE | rev | cut -d\. -f3- | rev`
VARNISHFOLDER=`echo $VARNISHFILE | rev | cut -d\. -f3- | rev`
HTTPDFOLDER=`echo $HTTPDFILE | rev | cut -d\. -f3- | rev`
FTPDFOLDER=`echo $FTPDFILE | rev | cut -d\. -f3- | rev`

IRCCONFIG=/etc/inspircd/inspircd.conf

REDISCONFIG=$HOMEROOT/$REDISUSER/redis.conf
REDISLOGS=$HOMEROOT/$REDISUSER
REDISPID=$HOMEROOT/$REDISUSER/redis.pid

#
# Create the users and groups we will need 
#

echo "*** Creating users and groups...."

groupadd -f thumbwhere

if [ `id -un $IRCUSER` != $IRCUSER ]
then
 	useradd $IRCUSER -m -g $GROUP
fi

if [ `id -un $REDISUSER` != $REDISUSER ]
then
	useradd $REDISUSER -m -g $GROUP
fi

if [ `id -un $NODEJSUSER` != $NODEJSUSER ]
then
	useradd $NODEJSUSER -m -g $GROUP
fi

if [ `id -un $VARNISHUSER` != $VARNISHUSER ]
then
	useradd $VARNISHUSER -m -g $GROUP
fi

if [ `id -un $HTTPDUSER` != $HTTPDUSER ]
then
	useradd $HTTPDUSER -m -g $GROUP
fi

if [ `id -un $FTPDUSER` != $FTPDUSER ]
then
	useradd $FTPDUSER -m -g $GROUP
fi

#
# Install the tools we will need
#

sudo apt-get -y install wget bzip2 binutils g++ make tcl8.5 libv8-dev curl build-essential openssl libssl-dev libssh-dev pkg-config libpcre3 libpcre3-dev libpcre++0 xsltproc libncurses5-dev

#
# Install the source packages...
#

echo "*** Downloading source packages"

mkdir -p $DOWNLOADS
cd $DOWNLOADS
[ -f $IRCFILE ] && echo "$IRCFILE exists" || wget $IRCURL
[ -f $REDISFILE ] && echo "$REDISFILE exists" || wget $REDISURL
[ -f $NODEJSFILE ] && echo "$NODEJSFILE exists" || wget $NODEJSURL
[ -f $VARNISHFILE ] && echo "$VARNISHFILE exists" || wget $VARNISHURL
[ -f $HTTPDFILE ] && echo "$HTTPDFILE exists" || wget $HTTPDURL
[ -f $FTPDFILE ] && echo "$FTPDFILE exists" || wget $FTPDURL
cd ..

#
# Install IRC
# 

if [ $INSTALL_IRC == 'true' ]
then
	echo "*** Installing IRC ($IRCFOLDER)"

	cp $DOWNLOADS/$IRCFILE $HOMEROOT/$IRCUSER
	chown $IRCUSER.$GROUP $HOMEROOT/$IRCUSER
	cd  $HOMEROOT/$IRCUSER
	echo " - Deleting old instance"
	#rm -rf $IRCFOLDER
	#rm -rf inspircd
	echo " - Uncompressing $IRCFILE"
	#tar -xjf $IRCFILE
	#mv inspircd $IRCFOLDER # For some reason this package unzips in 'inspircd' so we tweak that..
	echo " - Building $IRCFILE"
	cd $IRCFOLDER
	#./configure  --uid=$IRCUSER --disable-interactive  --prefix=$HOMEROOT/$IRCUSER/inspircd
	#make
	echo " - Installing $IRCFILE"
	#make install
	
# ---- IRC CONFIG -- START ----	
	
	cat > $IRCCONFIG << EOF
<config format="xml">
<define name="bindip" value="0.0.0.0">
<define name="localips" value="&bindip;/24">
<server name="irc.thumbwhere.com" description="ThumbWhere IRC Server" network="ThumbWhere">
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
<class name="Shutdown" commands="DIE RESTART REHASH LOADMODULE UNLOADMODULE RELOAD GUNLOADMODULE GRELOADMODULE SAJOIN SAPART SANICK SAQUIT SATOPIC"  
	    privs="users/auspex channels/auspex servers/auspex users/mass-message channels/high-join-limit channels/set-permanent users/flood/no-throttle users/flood/increased-buffers"     
		usermodes="*" chanmodes="*">
<class name="ServerLink" commands="CONNECT SQUIT CONNECT MKPASSWD ALLTIME SWHOIS CLOSE JUMPSERVER LOCKSERV" usermodes="*" chanmodes="*" privs="servers/auspex">
<class name="BanControl" commands="KILL GLINE KLINE ZLINE QLINE ELINE TLINE RLINE CHECK NICKLOCK SHUN CLONES CBAN" usermodes="*" chanmodes="*">
<class name="OperChat" commands="WALLOPS GLOBOPS SETIDLE" usermodes="*" chanmodes="*" privs="users/mass-message">
<class name="HostCloak" commands="SETHOST SETIDENT SETNAME CHGHOST CHGIDENT TAXONOMY" usermodes="*" chanmodes="*" privs="users/auspex">
<type name="NetAdmin" classes="OperChat BanControl HostCloak Shutdown ServerLink" vhost="netadmin.irc.thumbwhere.com" modes="+s +cCqQ">
<type name="GlobalOp" classes="OperChat BanControl HostCloak ServerLink" vhost="ircop.irc.thumbwhere.com">
<type name="Helper" classes="HostCloak" vhost="helper.irc.thumbwhere.com">
<oper name="ThumbWhere" hash="sha256" password="accff88f4b5fa17ac2bdf6fb7428119f999cf9bed698663a65a5681a4023d4fe" host="*@*" type="NetAdmin">
# LINKS
#<link name="hub.irc.thumbwhere.com" ipaddr="hub.irc.thumbwhere.com" port="7000" allowmask="*/24"  timeout="300"  ssl="openssl"  bind="&bindip;" statshidden="no" hidden="no" sendpass="outgoing!password" recvpass="incoming!password">
#<link name="services.irc.thumbwhere.com" ipaddr="localhost" port="7000" allowmask="127.0.0.0/8" sendpass="password" recvpass="password">
#<autoconnect period="300" server="hub.irc.thumbwhere.com">
#<autoconnect period="120" server="hub-backup.irc.thumbwhere.com ">
<uline server="services.irc.thumbwhere.com" silent="yes">
<files motd="$IRCCONFIG.motd" rules="$IRCCONFIG.rules">
#<execfiles rules="wget -O - http://www.example.com/rules.txt">
<channels users="20" opers="60">
<pid file="$HOMEROOT/$IRCUSER/inspircd.pid">
<banlist chan="*" limit="69">
#<disabled commands="TOPIC MODE" usermodes="" chanmodes="" fakenonexistant="yes">
<options prefixquit="Quit: " suffixquit="" prefixpart="&quot;" suffixpart="&quot;" syntaxhints="yes" cyclehosts="yes" cyclehostsfromuser="no" ircumsgprefix="no" announcets="yes" allowmismatched="no" defaultbind="auto" hostintopic="yes" pingwarning="15" serverpingfreq="60" defaultmodes="nt" moronbanner="You're banned! Email abuse@thumbwhere.com with the ERROR line below for help." exemptchanops="nonick:v flood:o" invitebypassmodes="yes">
<performance netbuffersize="10240" maxwho="4096" somaxconn="128" softlimit="12800" quietbursts="yes" nouserdns="no">
<security announceinvites="dynamic" hidemodes="eI" hideulines="no" flatlinks="no" hidewhois="" hidebans="no" hidekills="" hidesplits="no" maxtargets="20" customversion="" operspywhois="no" runasuser="tw-irc" restrictbannedusers="yes" genericoper="no" userstats="Pu">
<limits maxnick="31" maxchan="64" maxmodes="20" maxident="11" maxquit="255" maxtopic="307" maxkick="255" maxgecos="128" maxaway="200">
<log method="file" type="* -USERINPUT -USEROUTPUT" level="default" target="ircd.log">
<whowas groupsize="10" maxgroups="100000" maxkeep="3d">
<badnick nick="ChanServ" reason="Reserved For Services">
<badnick nick="NickServ" reason="Reserved For Services">
<badnick nick="OperServ" reason="Reserved For Services">
<badnick nick="MemoServ" reason="Reserved For Services">
<badhost host="root@*" reason="Don't irc as root!">
<badhost host="*@172.32.0.0/16" reason="This subnet is bad.">
<exception host="*@ircop.host.com" reason="Opers hostname">
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

cat > $IRCCONFIG.rules << EOF
These are the rules.
EOF

cat > $IRCCONFIG.motd << EOF
This is the MOTD
EOF

# ---- IRC CONFIG -- END ----


# ---- IRC CONTROL SCRIPT -- START --

	cat > /etc/init.d/tw-irc-server << EOF
#! /bin/sh
### BEGIN INIT INFO
# Provides:             tw-irc-server
# Required-Start:       $syslog $remote_fs
# Required-Stop:        $syslog $remote_fs
# Should-Start:         $local_fs
# Should-Stop:          $local_fs
# Default-Start:        2 3 4 5
# Default-Stop:         0 1 6
# Short-Description:    tw-irc-server - Persistent key-value db for ThumbWhere
# Description:          tw-irc-server - Persistent key-value db for ThumbWhere
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/local/bin/irc-server
NAME=irc-server
DESC=irc-server
PIDFILE=$IRCPID

test -x \$DAEMON || exit 0
test -x \$DAEMONBOOTSTRAP || exit 0

set -e

case "\$1" in
  start)
        echo -n "Starting \$DESC: "
        touch \$PIDFILE
        chown $IRCUSER:$GROUP \$PIDFILE
        if start-stop-daemon --start --quiet --umask 007 --pidfile \$PIDFILE --chuid $IRCUSER:$GROUP --exec \$DAEMON -- start
        then
                echo "\$NAME."
        else
                echo "failed"
        fi
        ;;
  stop)
        echo -n "Stopping \$DESC: "
        if start-stop-daemon --stop --retry 10 --quiet --oknodo --pidfile \$PIDFILE --exec \$DAEMON -- stop
        then
                echo "\$NAME."
        else
                echo "failed"
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

chmod +x /etc/init.d/tw-irc-server
chown root.root /etc/init.d/tw-irc-server
ln -fs /etc/init.d/tw-irc-server /etc/rc2.d/S19tw-irc-server

# ---- IRC CONTROL SCRIPT --- END ---

	echo " - Setting permissions"
	chown -R $IRCUSER.$GROUP $HOMEROOT/$IRCUSER/
fi

#
# Install Redis
#

if [ $INSTALL_REDIS == 'true' ]
then
	echo "*** Installing REDIS ($REDISFILE)"

	cp $DOWNLOADS/$REDISFILE $HOMEROOT/$REDISUSER
	chown $REDISUSER.$GROUP $HOMEROOT/$REDISUSER
	cd  $HOMEROOT/$REDISUSER
	echo " - Deleting old instance"
	rm -rf $REDISFOLDER
	echo " - Uncompressing $REDISILE"
	tar -xvf $REDISFILE
	echo " - Building $REDISFILE"
	cd $REDISFOLDER
	#make
	echo " - Testing $REDISFILE"
	#make test
	echo " - Installing $REDISFILE"
	#make install

	# 
	# Generate configure scripts
	#	


	echo " - Configuring"




# --- REDIS CONTROL SCRIPT -- START ----
	
	cat > /etc/init.d/tw-redis-server << EOF
#! /bin/sh
### BEGIN INIT INFO
# Provides:             tw-redis-server
# Required-Start:       $syslog $remote_fs
# Required-Stop:        $syslog $remote_fs
# Should-Start:         $local_fs
# Should-Stop:          $local_fs
# Default-Start:        2 3 4 5
# Default-Stop:         0 1 6
# Short-Description:    tw-redis-server - Persistent key-value db for ThumbWhere
# Description:          tw-redis-server - Persistent key-value db for ThumbWhere
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/local/bin/redis-server
DAEMON_ARGS=$REDISCONFIG
NAME=redis-server
DESC=redis-server
PIDFILE=$REDISPID

test -x \$DAEMON || exit 0
test -x \$DAEMONBOOTSTRAP || exit 0

set -e

case "\$1" in
  start)
        echo -n "Starting \$DESC: "
        touch \$PIDFILE
        chown $REDISUSER:$GROUP \$PIDFILE
        if start-stop-daemon --start --quiet --umask 007 --pidfile \$PIDFILE --chuid $REDISUSER:$GROUP --exec \$DAEMON -- \$DAEMON_ARGS
        then
                echo "\$NAME."
        else
                echo "failed"
        fi
        ;;
  stop)
        echo -n "Stopping \$DESC: "
        if start-stop-daemon --stop --retry 10 --quiet --oknodo --pidfile \$PIDFILE --exec \$DAEMON
        then
                echo "\$NAME."
        else
                echo "failed"
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

chmod +x /etc/init.d/tw-redis-server
chown root.root /etc/init.d/tw-redis-server
ln -fs /etc/init.d/tw-redis-server /etc/rc2.d/S19tw-redis-server 

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

fi

#
# Install NODEJS
#

if [ $INSTALL_NODEJS == 'true' ]
then
        echo "*** Installing NODEJS ($NODEJSFOLDER)"

        cp $DOWNLOADS/$NODEJSFILE $HOMEROOT/$NODEJSUSER
        chown $NODEJSUSER.$GROUP $HOMEROOT/$NODEJSUSER
        cd  $HOMEROOT/$NODEJSUSER
        echo " - Deleting old instance"
        rm -rf $NODEJSFOLDER
        echo " - Uncompressing"
        tar -xzf $NODEJSFILE
        echo " - Building"
        cd $NODEJSFOLDER
        ./configure --shared-zlib --shared-cares  --sysconfdir=$HOMEROOT/$NODEJSUSER/
        make
	echo " - Testing"
	make test
        echo " - Installing"
        make install
	echo " - Configuring"

        echo " - Setting permissions"
        chown -R $NODEJSUSER.$GROUP $HOMEROOT/$NODEJSUSER/

fi

#
# Install VARNISH
#

if [ $INSTALL_VARNISH == 'true' ]
then
        echo "*** Installing VARNISH ($VARNISHFOLDER)"

        cp $DOWNLOADS/$VARNISHFILE $HOMEROOT/$VARNISHUSER
        chown $VARNISHUSER.$GROUP $HOMEROOT/$VARNISHUSER
        cd  $HOMEROOT/$VARNISHUSER
        echo " - Deleting old instance"
        rm -rf $VARNISHFOLDER
        echo " - Uncompressing"
        tar -xzf $VARNISHFILE
        echo " - Building"
        cd $VARNISHFOLDER
        ./configure  --sysconfdir=$HOMEROOT/$VARNISHUSER/
        make
        #echo " - Testing"
        #make test
        echo " - Installing"
        make install
        echo " - Configuring"

        echo " - Setting permissions"
        chown -R $VARNISHUSER.$GROUP $HOMEROOT/$VARNISHUSER/

fi

#
# Install HTTPD
#

if [ $INSTALL_HTTPD == 'true' ]
then
        echo "*** Installing HTTPD ($HTTPDFOLDER)"

        cp $DOWNLOADS/$HTTPDFILE $HOMEROOT/$HTTPDUSER
        chown $HTTPDUSER.$GROUP $HOMEROOT/$HTTPDUSER
        cd  $HOMEROOT/$HTTPDUSER
        echo " - Deleting old instance"
        rm -rf $HTTPDFOLDER
        echo " - Uncompressing"
        tar -xzf $HTTPDFILE
        echo " - Building"
        cd $HTTPDFOLDER
        ./configure  --sysconfdir=$HOMEROOT/$HTTPDUSER/
        make
        #echo " - Testing"
        #make test
        echo " - Installing"
        make install
        echo " - Configuring"

        echo " - Setting permissions"
        chown -R $HTTPDUSER.$GROUP $HOMEROOT/$HTTPDUSER/

fi

#
# Install FTPD
#

if [ $INSTALL_FTPD == 'true' ]
then
        echo "*** Installing FTPD ($FTPDFOLDER)"

        cp $DOWNLOADS/$FTPDFILE $HOMEROOT/$FTPDUSER
        chown $FTPDUSER.$GROUP $HOMEROOT/$FTPDUSER
        cd  $HOMEROOT/$FTPDUSER
        echo " - Deleting old instance"
        rm -rf $FTPDFOLDER
        echo " - Uncompressing"
        tar -xzf $FTPDFILE
        echo " - Building"
        cd $FTPDFOLDER
        ./configure  --sysconfdir=$HOMEROOT/$FTPDUSER/
        make
        #echo " - Testing"
        #make test
        echo " - Installing"
        make install
        echo " - Configuring"

        echo " - Setting permissions"
        chown -R $FTPDUSER.$GROUP $HOMEROOT/$FTPDUSER/

fi



