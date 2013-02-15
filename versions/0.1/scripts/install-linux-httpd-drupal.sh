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
if [ "$DRUPALADMIN" = "" ]
then
    DRUPALADMIN=admin
fi

if [ "$DRUPALADMINPASSWORD" = "" ]
then
    DRUPALADMINPASSWORD=new-password 
fi

if [ "$DRUPALADMINEMAIL" = "" ]
then
    DRUPALADMINEMAIL=log@thumbwhere.com
fi

if [ "$DRUPALEMAIL" = "" ]
then
    DRUPALEMAIL=log@thumbwhere.com
fi


# related to drupal..
PHPUSER=tw-php
PHPROOT=$HOMEROOT/$PHPUSER/php

MYSQLDUSER=tw-mysqld
MYSQLDSOCKET=$HOMEROOT/$MYSQLDUSER/mysqld.sock
MYSQLDCONFIG=$HOMEROOT/$DRUPALUSER/.my.cnf
if [ "$MYSQLDPASSWORD" = "" ] 
then
	MYSQLDPASSWORD=new-password
fi


###############################################################################
#
# Config variables ; Each one can contain the following keywords "download,compile,install,configure,enable"
# If enable is not part of the string, then the service is deemed to be 'disabled'
#

if [[ $DRUPAL_ROLE = "" ]] 
then
	DRUPAL_ROLE=download,compile,install,configure,enable
fi

###############################################################################
#
# Config variables ; Each one can contain the following keywords "download,compile,install,configure,enable"
# If enable is not part of the string, then the service is deemed to be 'disabled'
#

DRUPALURL=http://ftp.drupal.org/files/projects/drupal-7.19.tar.gz

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
      'password' => '$MYSQLDPASSWORD',
      'host' => 'localhost',
      'port' => '',
      'driver' => 'mysql',
      'prefix' => '',
    ),
  ),
);

\$conf['user_mail_register_no_approval_required_notify'] = FALSE; 
\$conf['user_mail_register_admin_created'] = FALSE;
\$conf['user_mail_register_pending_approval'] = FALSE;
\$conf['user_mail_status_activated'] = FALSE;
\$conf['user_mail_password_reset'] = FALSE;
\$conf['user_mail_status_blocked'] = FALSE;
\$conf['user_mail_status_deleted'] = FALSE;

EOF

cat >> php.ini << EOF
extension=php_openssl.dll
EOF


		#pwd
		
		# Now perform the install
		#drush dl drupal-7.x --yes
		
		DRUSH_PHP=$PHPROOT

		#sleep 5

		echo "START SITE INSTALL"
		
		$PHPROOT/bin/php -d sendmail_path=/bin/true /usr/bin/drush --debug --verbose site-install standard --account-name=$DRUPALADMIN --account-pass=$DRUPALADMINPASSWORD --account-mail=$DRUPALADMINEMAIL --site-mail=$DRUPALEMAIL --url=http://localhost:81 --db-url=mysql://root:$MYSQLDPASSWORD@localhost/drupal --yes

		echo "FINISH SITE INSTALL"
			
		chmod 775 sites/default/files
		chmod 775 sites/default/settings.php	

		echo "Downloading Modules"

		$PHPROOT/bin/php /usr/bin/drush pm-download ctools --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download views --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download entity --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download date --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download views_bulk_operations --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download rules --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download rules_link --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download entityreference --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download wysiwyg --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download menu_attributes --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download token --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download pathauto --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download globalredirect --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download admin_menu --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download features --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download panels --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download module_filter-1.7 --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download filefield_paths --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download logging_alerts --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download progress --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download libraries --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download services-3.x-dev --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download services_views-1.x-dev --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download skinr --yes --verbose --debug 
 		$PHPROOT/bin/php /usr/bin/drush pm-download lightbox2-1.0-beta1 --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-download captcha-1.0-beta2 --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-download recaptcha-1.7 --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-download libraries --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-download oauth --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-download services --dev --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-download services_views --dev --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-download services_entity --dev --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-download services_rules --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-download search_api --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-download services_search_api --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-download hierarchical_select-3.0-alpha5 --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-download wsclient --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-download http_client --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download live_css --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download connector --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-download oauthconnector --yes --verbose --debug
 		$PHPROOT/bin/php /usr/bin/drush pm-download sociallogin --yes --verbose --debug

		echo "Enabling Modules"
	
		$PHPROOT/bin/php /usr/bin/drush pm-enable entity --yes --verbose --debug		
		$PHPROOT/bin/php /usr/bin/drush pm-enable ctools --yes --verbose --debug		
		$PHPROOT/bin/php /usr/bin/drush pm-enable views --yes --verbose --debug				
		$PHPROOT/bin/php /usr/bin/drush pm-enable date --yes --verbose --debug		
		$PHPROOT/bin/php /usr/bin/drush pm-enable simpletest --yes --verbose --debug		
		$PHPROOT/bin/php /usr/bin/drush pm-enable views_bulk_operations  --yes --verbose --debug		
		$PHPROOT/bin/php /usr/bin/drush pm-enable emaillog --yes --verbose --debug		
		$PHPROOT/bin/php /usr/bin/drush pm-enable errorlog --yes --verbose --debug		
		$PHPROOT/bin/php /usr/bin/drush pm-enable watchdog_rules --yes --verbose --debug		
		$PHPROOT/bin/php /usr/bin/drush pm-enable watchdog_triggers --yes --verbose --debug		
		$PHPROOT/bin/php /usr/bin/drush pm-enable rules --yes --verbose --debug		
		$PHPROOT/bin/php /usr/bin/drush pm-enable rules_scheduler --yes --verbose --debug		
		$PHPROOT/bin/php /usr/bin/drush pm-enable entityreference --yes	--verbose --debug	
		$PHPROOT/bin/php /usr/bin/drush pm-enable wysiwyg --yes --verbose --debug		
		$PHPROOT/bin/php /usr/bin/drush pm-enable menu_attributes --yes --verbose --debug		
		$PHPROOT/bin/php /usr/bin/drush pm-enable token --yes --verbose --debug				
		$PHPROOT/bin/php /usr/bin/drush pm-enable pathauto --yes --verbose --debug				
		$PHPROOT/bin/php /usr/bin/drush pm-enable globalredirect --yes --verbose --debug				
		$PHPROOT/bin/php /usr/bin/drush pm-enable admin_menu --yes --verbose --debug				
		$PHPROOT/bin/php /usr/bin/drush pm-enable admin_menu_toolbar --yes --verbose --debug 				
		$PHPROOT/bin/php /usr/bin/drush pm-enable features --yes --verbose --debug				
		$PHPROOT/bin/php /usr/bin/drush pm-enable panels --yes --verbose --debug				
		$PHPROOT/bin/php /usr/bin/drush pm-enable page_manager --yes --verbose --debug				
		$PHPROOT/bin/php /usr/bin/drush pm-enable module_filter --yes --verbose --debug				
		$PHPROOT/bin/php /usr/bin/drush pm-enable rules_link --yes --verbose --debug				
		$PHPROOT/bin/php /usr/bin/drush pm-enable filefield_paths --yes	--verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-enable skinr --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-enable lightbox --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-enable captcha --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-enable recaptcha --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-enable libraries --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-enable oauth --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-enable services --dev --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-enable services_views --dev --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-enable services_entity --dev --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-enable services_rules --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-enable search_api --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-enable services_search_api --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-enable hierarchical_select --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-enable wsclient --yes --verbose --debug
                $PHPROOT/bin/php /usr/bin/drush pm-enable http_client --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-enable live_css --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-disable toolbar --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-enable connector --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-enable oauthconnector --yes --verbose --debug
		$PHPROOT/bin/php /usr/bin/drush pm-enable sociallogin --yes --verbose --debug

		echo "Downloading Themes"
	        
		$PHPROOT/bin/php /usr/bin/drush dl omega --yes
		$PHPROOT/bin/php /usr/bin/drush dl omega_tools --yes
		$PHPROOT/bin/php /usr/bin/drush dl context --yes

		#$PHPROOT/bin/php /usr/bin/drush pm-enable omega --yes
		$PHPROOT/bin/php /usr/bin/drush pm-enable omega_tools --yes
		$PHPROOT/bin/php /usr/bin/drush pm-enable context --yes
		#$PHPROOT/bin/php /usr/bin/drush vset theme_default omega --yes	
		
		$PHPROOT/bin/php /usr/bin/drush omega-subtheme "my64k_theme" --yes # --destination=mysite.
		$PHPROOT/bin/php /usr/bin/drush pm-enable my64k_theme --yes
		$PHPROOT/bin/php /usr/bin/drush vset theme_default my64k_theme --yes					
		
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
