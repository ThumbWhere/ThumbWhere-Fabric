#!/bin/bash
# Proper header for a Bash script.

###############################################################################
#
# This will setup Drupal in ThumbWhere Fabric
#
# Although this script can be run manually, in will generally
# be executed as part of an automated install if thumbwhere is 
# configured with credentials of the target host that can perform 
# tasks as root or use sudo.
#
#
# Prerequisites
# -------------
#
# Requires that the httpd role has already been installed using install-linux-roles.sh with HTTPD_ROLE="download,compile,install,configure,enable"
# Requires that the mysqld role has already been installed using install-linux-roles.sh with HTTPD_ROLE="download,compile,install,configure,enable"
#
# Bootstrapping
# -------------
#
# This script can be downloaded using the following command
# 
# For systems with wget, run this line.
#
# rm install-linux-apache-drupal.sh; wget -nc https://raw.github.com/ThumbWhere/ThumbWhere-Fabric/master/versions/0.1/scripts/install-linux-apache-drupal.sh; chmod +x install-linux-apache-drupal.sh ; sudo -E bash ./install-linux-apache-drupal.sh
#
# For systems with curl, run this line
#
# curl -O https://raw.github.com/ThumbWhere/ThumbWhere-Fabric/master/versions/0.1/scripts/install-linux-apache-drupal.sh; chmod +x install-linux-apache-drupal.sh; sudo -E bash ./install-linux-apache-drupal.sh
# 
#

# We want the script to fail on any errors... so..
set -e

#
# Global config.
#

HOMEROOT=/home
GROUP=thumbwhere

#
# Drupal specific.
#

DRUPALUSER=tw-drupal
DRUPALCONFIG=$HOMEROOT/$DRUPALUSER/drupal.config
DRUPALSITE=default



# related to drupal..
PHPUSER=tw-php
PHPROOT=$HOMEROOT/$PHPUSER/php

MYSQLDUSER=tw-mysqld
MYSQLDSOCKET=$HOMEROOT/$MYSQLDUSER/mysqld.sock
MYSQLDCONFIG=$HOMEROOT/$DRUPALUSER/.my.cnf
if ["$MYSQLDPASSWORD" = ""] 
then
	MYSQLDPASSWORD=new-password
fi



###############################################################################
#
# Config variables ; Each one can contain the following keywords "download,compile,install,configure,enable"
# If enable is not part of the string, then the service is deemed to be 'disabled'
#

if [$DRUPAL_ROLE = ""] 
then
	DRUPAL_ROLE=download,compile,install,configure,enable
fi

###############################################################################
#
# Config variables ; Each one can contain the following keywords "download,compile,install,configure,enable"
# If enable is not part of the string, then the service is deemed to be 'disabled'
#

DRUPALURL=http://ftp.drupal.org/files/projects/drupal-7.15.tar.gz

###############################################################################
#
# Generate some more convenient variables based on our config.
#

DOWNLOADS=~/tw-downloads

DRUPALFILE=`echo $DRUPALURL | rev | cut -d\/ -f1 | rev`
DRUPALFOLDER=`echo $DRUPALFILE | rev | cut -d\. -f3- | rev`


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
fi

if [ "$os" = "" ] 
then
	echo "Unable to determine os from `cat /proc/version -c`"
	exit 1
fi

#
# What packages do we want?
#

if [ $os = "debian" ] || [ $os = "ubuntu" ]
then
	apt-get -y install drush php5-gd
elif [ $os = "centos" ]
then
	yum -y install drush php-gd
fi

#
# Install the source packages...
#

echo "*** ${cc_cyan}Downloading source packages${cc_normal}"

mkdir -p $DOWNLOADS
cd $DOWNLOADS

if [[ $DRUPAL_ROLE = *download* ]] 
then
	[ -f $DRUPALFILE ] && echo " - $DRUPALFILE exists" || wget $DRUPALURL
else
	echo " - ${cc_yellow}Skipping $DRUPALFILE${cc_normal}"
fi


cd ..

###############################################################################
#
# Install DRUPAL
# 

if [ "$DRUPAL_ROLE" != "" ]
then
	echo "$*** ${cc_cyan}Installing DRUPAL ($DRUPALFOLDER)${cc_normal}"
	
	create_user $DRUPALUSER

	if [[ $DRUPAL_ROLE = *install* ]]
	then
		echo " - Installing"
				

		cd $HOMEROOT/$DRUPALUSER
		
		cp $DOWNLOADS/$DRUPALFILE .
		tar -xf $DRUPALFILE
				
		rm -rf $DRUPALSITE				
		mv $DRUPALFOLDER $DRUPALSITE
		cd $DRUPALSITE
		
		# Need some local config for mysql
		
		# ---- INSTALL CONFIG -- START --
		cat > $MYSQLDCONFIG << EOF
[client]
port            = 3306
socket          = $MYSQLDSOCKET
EOF

		# Wire drush up to mysqld socket
		cat > $HOMEROOT/$DRUPALUSER/$DRUPALSITE/drushrc.php << EOF
$option['mysql-socket'] = '/home/tw-mysqld/mysqld.sock'		
EOF
		
		
		# we want a version of this too...
		cp $MYSQLDCONFIG ~
		
		# And we want SQL server started..
		/etc/init.d/$MYSQLDUSER-server restart
			
		mkdir sites/default/files			
		chmod 777 sites/default/files	
		cp sites/default/default.settings.php  sites/default/settings.php
		chmod 777 sites/default/settings.php
		
cat >> sites/default/settings.php << EOF		

\$databases = array (
  'default' =>
  array (
    'default' =>
    array (
      'database' => 'drupal',
      'username' => 'root',
      'password' => 'new-password',
      'host' => 'localhost',
      'port' => '',
      'driver' => 'mysql',
      'prefix' => '',
    ),
  ),
);
EOF
			
		
		pwd
		
		# Now perform the install
		#drush dl drupal-7.x --yes
		
		DRUSH_PHP=$PHPROOT
		
		echo $PHPROOT/bin/php /usr/bin/drush site-install standard --debug --verbose --account-name=admin --account-pass=wjpq6q --url=http://localhost:81 --db-url=mysql://root:new-password@localhost/drupal --yes
		
		$PHPROOT/bin/php /usr/bin/drush site-install standard --debug --verbose --account-name=admin --account-pass=wjpq6q --url=http://localhost:81 --db-url=mysql://root:new-password@localhost/drupal --yes

			
		chmod 775 sites/default/files
		chmod 775 sites/default/settings.php		
		
		
	fi

	#
	# Generate configure scripts
	#
	
	if [[ $DRUPAL_ROLE = *configure* ]]
	then
		# ---- DRUPAL CONFIG -- START ----		
	
		cat > $DRUPALCONFIG.test << EOF
Hello Cruel World
EOF

		# ---- DRUPAL CONFIG -- END ----
	fi

	echo " - Setting permissions"
	chown -R $DRUPALUSER.$GROUP $HOMEROOT/$DRUPALUSER/

fi


#
# And we are done..
#

echo " *** ${cc_cyan}Completed${cc_normal}"
echo ""
