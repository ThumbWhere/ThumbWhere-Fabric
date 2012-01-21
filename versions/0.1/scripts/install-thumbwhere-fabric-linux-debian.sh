########################################################
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

IRCFOLDER=inspircd
REDISFOLDER=`echo $REDISFILE | rev | cut -d\. -f3- | rev`
NODEJSFOLDER=`echo $NODEJSFILE | rev | cut -d\. -f3- | rev`
VARNISHFOLDER=`echo $VARNISHFILE | rev | cut -d\. -f3- | rev`
HTTPDFOLDER=`echo $HTTPDFILE | rev | cut -d\. -f3- | rev`
FTPDFOLDER=`echo $FTPDFILE | rev | cut -d\. -f3- | rev`

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
	rm -rf $IRCFOLDER
	echo " - Uncompressing $IRCFILE"
	tar -xjf $IRCFILE
	echo " - Building $IRCFILE"
	cd $IRCFOLDER
	./configure  --uid=$IRCUSER --disable-interactive  --sysconfdir=$HOMEROOT/$FTPDUSER/
	make
	echo " - Installing $IRCFILE"
	#make INSTUID=` id -u $IRCUSER` install
	make install
	cp /etc/inspircd/inspircd.conf.example /etc/inspircd/inspircd.conf

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



