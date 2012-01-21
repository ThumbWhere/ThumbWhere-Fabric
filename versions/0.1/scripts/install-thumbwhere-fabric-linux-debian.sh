#######################################################
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

INSTALL_IRC=false
INSTALL_REDIS=false
INSTALL_NODEJS=false
INSTALL_VARNISH=true
INSTALL_HTTPD=false
INSTALL_FTPD=false

IRCURL=http://downloads.sourceforge.net/project/inspircd/InspIRCd-2.0/2.0.2/InspIRCd-2.0.2.tar.bz2
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
IRCPID=$HOMEROOT/$IRCUSER/inspircd.pid

REDISCONFIG=$HOMEROOT/$REDISUSER/redis.conf
REDISLOGS=$HOMEROOT/$REDISUSER
REDISPID=$HOMEROOT/$REDISUSER/redis.pid

VARNISHCONFIG=$HOMEROOT/$VARNISHUSER/thumbwhere.vcl

groupadd -f thumbwhere

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


###############################################################################
#
# Install IRC
# 

if [ $INSTALL_IRC == 'true' ]
then
	echo "*** Installing IRC ($IRCFOLDER)"

	if [ `id -un $IRCUSER` != $IRCUSER ]
	then
		 echo " - Adding user $IRCUSER"
        	useradd $IRCUSER -m -g $GROUP
	else
		 echo " - Stopping service"
        	/etc/init.d/$IRCUSER-server stop
	fi

	cp $DOWNLOADS/$IRCFILE $HOMEROOT/$IRCUSER
	chown $IRCUSER.$GROUP $HOMEROOT/$IRCUSER
	cd  $HOMEROOT/$IRCUSER
	echo " - Deleting old instance"
	rm -rf $IRCFOLDER
	rm -rf inspircd
	echo " - Uncompressing"
	tar -xjf $IRCFILE
	mv inspircd $IRCFOLDER # For some reason this package unzips in 'inspircd' so we tweak that..
	echo " - Building"
	cd $IRCFOLDER
	./configure  --uid=$IRCUSER --disable-interactive
	make
	echo " - Installing"
	make install

	#
	# Generate configure scripts
	#

	
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
<pid file="$IRCPID">
<banlist chan="*" limit="69">
#<disabled commands="TOPIC MODE" usermodes="" chanmodes="" fakenonexistant="yes">
<options prefixquit="Quit: " suffixquit="" prefixpart="&quot;" suffixpart="&quot;" syntaxhints="yes" cyclehosts="yes" cyclehostsfromuser="no" ircumsgprefix="no" announcets="yes" allowmismatched="no" defaultbind="auto" hostintopic="yes" pingwarning="15" serverpingfreq="60" defaultmodes="nt" moronbanner="You're banned! Email abuse@thumbwhere.com with the ERROR line below for help." exemptchanops="nonick:v flood:o" invitebypassmodes="yes">
<performance netbuffersize="10240" maxwho="4096" somaxconn="128" softlimit="12800" quietbursts="yes" nouserdns="no">
<security announceinvites="dynamic" hidemodes="eI" hideulines="no" flatlinks="no" hidewhois="" hidebans="no" hidekills="" hidesplits="no" maxtargets="20" customversion="" operspywhois="no" runasuser="$IRCUSER" restrictbannedusers="yes" genericoper="no" userstats="Pu">
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

	cat > /etc/init.d/$IRCUSER-server << EOF
#!/bin/sh
### BEGIN INIT INFO
# Provides:          $IRCUSER-server
# Required-Start:    \$network \$syslog \$time
# Required-Stop:     \$syslog
# Should-Start:      \$local_fs
# Should-Stop:       \$local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Controls the irc server
# Description:       Controls the irc server.
### END INIT INFO
# GPL Licensed

# Source function library
. /lib/lsb/init-functions

IRCD="/usr/sbin/inspircd"
IRCDPID="$IRCPID"
IRCDLOG="/var/log/inspircd.log"
IRCDCONFIG="$IRCCONFIG"
IRCDARGS="--logfile \$IRCDLOG --config \$IRCDCONFIG"
USER="$IRCUSER"
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

#if [ -f "/var/lib/inspircd/inspircd" ]; then
#        . /var/lib/inspircd/inspircd
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
        start-stop-daemon --start --quiet --oknodo --chuid "\$USER" --pidfile "\$IRCDPID" --exec "\$IRCD" --  \$IRCDARGS
}

stop_ircd()
{
        start-stop-daemon --stop --quiet --pidfile "\$IRCDPID" 
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
        #        echo -n "Please configure inspircd first and edit /etc/default/inspircd, otherwise inspircd won't start"
        #        exit 0
        #fi
        echo -n "Starting Inspircd... "
        start_ircd && echo "done."
        ;;
  stop)
        echo -n "Stopping Inspircd... "
        stop_ircd && echo "done."
        ;;
  force-reload|reload)
        echo -n "Reloading Inspircd... "
        reload_ircd && echo "done."
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

chmod +x /etc/init.d/$IRCUSER-server
insserv /etc/init.d/$IRCUSER-server
chown root.root /etc/init.d/$IRCUSER-server
#ln -fs /etc/init.d/$IRCUSER-server /etc/rc2.d/S19$IRCUSER-server

# ---- IRC CONTROL SCRIPT --- END ---

	echo " - Setting permissions"
	chown -R $IRCUSER.$GROUP $HOMEROOT/$IRCUSER/

	echo " - Starting service"
	/etc/init.d/$IRCUSER-server start

fi


###############################################################################
#
# Install Redis
#

if [ $INSTALL_REDIS == 'true' ]
then
	echo "*** Installing REDIS ($REDISFILE)"
	if [ `id -un $REDISUSER` != $REDISUSER ]
	then
		 echo " - Adding user $REDISUSER"
		useradd $REDISUSER -m -g $GROUP
	else
		/etc/init.d/$REDISUSER-server stop
	fi
	cp $DOWNLOADS/$REDISFILE $HOMEROOT/$REDISUSER
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
# Provides:             $REDISUSER-server
# Required-Start:       $syslog $remote_fs
# Required-Stop:        $syslog $remote_fs
# Should-Start:         $local_fs
# Should-Stop:          $local_fs
# Default-Start:        2 3 4 5
# Default-Stop:         0 1 6
# Short-Description:    $REDISUSER-server - Persistent key-value db for ThumbWhere
# Description:          $REDISUSER-server - Persistent key-value db for ThumbWhere
### END INIT INFO

# Source function library
. /lib/lsb/init-functions

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
		 log_end_msg 0
        else
		 log_end_msg 1
        fi
        ;;
  stop)
        echo -n "Stopping \$DESC: "
        if start-stop-daemon --stop --retry 10 --quiet --oknodo --pidfile \$PIDFILE --exec \$DAEMON
        then
		log_end_msg 0
        else
		log_end_msg 1
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
insserv /etc/init.d/$REDISUSER-server
#ln -fs /etc/init.d/$REDISUSER-server /etc/rc2.d/S19$REDISUSER-server 

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

if [ $INSTALL_NODEJS == 'true' ]
then
        echo "*** Installing NODEJS ($NODEJSFOLDER)"

	if [ `id -un $NODEJSUSER` != $NODEJSUSER ]
	then
		echo " - Adding user $NODEJSUSER"
		useradd $NODEJSUSER -m -g $GROUP
	fi

        cp $DOWNLOADS/$NODEJSFILE $HOMEROOT/$NODEJSUSER
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

if [ $INSTALL_VARNISH == 'true' ]
then
        echo "*** Installing VARNISH ($VARNISHFOLDER)"

	
	if [ `id -un $VARNISHUSER` != $VARNISHUSER ]
	then
		echo " - Adding user $VARNISHUSER"
		useradd $VARNISHUSER -m -g $GROUP
	else
		echo " - Starting service"
		/etc/init.d/$VARNISHUSER-server stop
	fi

        cp $DOWNLOADS/$VARNISHFILE $HOMEROOT/$VARNISHUSER
        chown $VARNISHUSER.$GROUP $HOMEROOT/$VARNISHUSER
        cd  $HOMEROOT/$VARNISHUSER
        echo " - Deleting old instance"
        #rm -rf $VARNISHFOLDER
        echo " - Uncompressing"
        #tar -xzf $VARNISHFILE
        echo " - Building"
        cd $VARNISHFOLDER
        #./configure 
        #make
        echo " - Installing"
        make install
        echo " - Configuring"

# ---- VARNISH CONTROL SCRIPT -- START ----

        cat > /etc/init.d/$VARNISHUSER-server << EOF
#! /bin/sh

### BEGIN INIT INFO
# Provides:          $VARNISHUSER-server
# Required-Start:    \$local_fs \$remote_fs \$network
# Required-Stop:     \$local_fs \$remote_fs \$network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start HTTP accelerator
# Description:       This script provides a server-side cache
#                    to be run in front of a httpd and should
#                    listen on port 80 on a properly configured
#                    system
### END INIT INFO

# Source function library
. /lib/lsb/init-functions

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
	.host = "127.0.0.1";
	.port = "80";
}
EOF

# ---- VARNISH CONFIG -- END ----

chmod +x /etc/init.d/$VARNISHUSER-server
chown root.root /etc/init.d/$VARNISHUSER-server
insserv /etc/init.d/$VARNISHUSER-server
#ln -fs /etc/init.d/$VARNISHUSER-server /etc/rc2.d/S19$VARNISHUSER-server

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
