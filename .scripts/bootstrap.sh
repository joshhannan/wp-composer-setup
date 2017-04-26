#!/usr/bin/env bash


echo "=================================================="
echo "STARTING INSTALLATION..."
echo "=================================================="
echo ""
echo ""
echo "=================================================="
echo "SET LOCALES"
echo "=================================================="

export DEBIAN_FRONTEND=noninteractive

export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_TYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US en_US.UTF-8
dpkg-reconfigure locales

echo "=================================================="
echo "ADDING PHP 5.6 REPOSITORY"
echo "=================================================="
add-apt-repository -y ppa:ondrej/php5-5.6

echo "=================================================="
echo "RUNNING UPDATE"
echo "=================================================="

apt-get update
apt-get upgrade

echo "=================================================="
echo "INSTALLING APACHE"
echo "=================================================="

apt-get -y install apache2

if [ ! -d /vagrant/public_html ]; then
  mkdir /vagrant/public_html
fi

if [ ! -L /var/www ]; then
  rm -rf /var/www
  ln -fs /vagrant/public_html /var/www
fi

if [ ! -d /vagrant/.vagrant/logs ]; then
  mkdir /vagrant/.vagrant/logs
fi

VHOST=$(cat <<EOF
<VirtualHost *:80>
    DocumentRoot "/var/www"
    ServerName dietz.dev
    ServerName 15.15.15.15

    ErrorLog "/vagrant/.vagrant/logs/error.log"
    CustomLog "/vagrant/.vagrant/logs/access.log" combined

    <Directory "/var/www">
        Options Indexes FollowSymLinks MultiViews
        AllowOverride all
        Require all granted
    </Directory>

    Alias /phpmyadmin "/home/vagrant/phpmyadmin-master"

    <Directory "/home/vagrant/phpmyadmin-master">
        Options Indexes FollowSymLinks MultiViews
        AllowOverride all
        Require all granted
    </Directory>

    Alias /webmail "/home/vagrant/roundcubemail-1.2.0"

    <Directory "/home/vagrant/roundcubemail-1.2.0">
        Options Indexes FollowSymLinks MultiViews
        AllowOverride all
        Require all granted
    </Directory>

    SetEnv MAGE_IS_DEVELOPER_MODE true

</VirtualHost>
EOF
)
echo "$VHOST" > /etc/apache2/sites-available/000-default.conf

echo "ServerName localhost" | sudo tee /etc/apache2/conf-available/localhost.conf

a2enconf localhost
a2enmod rewrite headers

service apache2 restart

echo "=================================================="
echo "INSTALLING PHP"
echo "=================================================="


# Install Apache & PHP
# --------------------
apt-get install -y apache2
apt-get install -y php5
apt-get install -y libapache2-mod-php5
apt-get install -y php5-mysql php5-curl php5-xdebug php5-gd php5-intl php-pear php5-imap php5-mcrypt php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl php-soap

# Install the PHP configuration file
cp /vagrant/.configs/php.ini /etc/php5/apache2/php.ini
cp /vagrant/.configs/php.ini /etc/php5/cli/php.ini

php5enmod mcrypt
service apache2 restart

echo "=================================================="
echo "INSTALLING NTP"
echo "=================================================="
apt-get -y install ntp

echo "=================================================="
echo "INSTALLING MYSQL"
echo "=================================================="
apt-get -q -y install mysql-server-5.6

# Install the MySQL configuration file
cp /vagrant/.configs/my.cnf /etc/mysql/conf.d/vagrant-my.cnf

#reboot MySQL to pick up new config
service mysql restart

echo "=================================================="
echo "CLEANING..."
echo "=================================================="
apt-get -y autoremove
apt-get -y autoclean


# install unzip so we can extract the latest PHP My Admin
apt-get install -y unzip

#install composer if it isn't installed yet

if [ ! -f /usr/local/bin/composer ]; then

echo "=================================================="
echo "INSTALLING COMPOSER"
echo "=================================================="

curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

else

echo "=================================================="
echo "COMPOSER ALREADY INSTALLED, SKIPPING"
echo "=================================================="

fi



if [ ! -d /home/vagrant/roundcubemail-1.2.0 ]; then

echo "=================================================="
echo "INSTALLING ROUNDCUBE WEBMAIL"
echo "=================================================="

wget --quiet https://github.com/roundcube/roundcubemail/releases/download/1.2.0/roundcubemail-1.2.0-complete.tar.gz -O /home/vagrant/roundcubemail-1.2.0.tar.gz

tar -xzf /home/vagrant/roundcubemail-1.2.0.tar.gz -C /home/vagrant

ROUNDCUBECONFIG=$(cat <<EOF
<?php

/* Local configuration for Roundcube Webmail */

// ----------------------------------
// SQL DATABASE
// ----------------------------------
// Database connection string (DSN) for read+write operations
// Format (compatible with PEAR MDB2): db_provider://user:password@host/database
// Currently supported db_providers: mysql, pgsql, sqlite, mssql, sqlsrv, oracle
// For examples see http://pear.php.net/manual/en/package.database.mdb2.intro-dsn.php
// NOTE: for SQLite use absolute path (Linux): 'sqlite:////full/path/to/sqlite.db?mode=0646'
//       or (Windows): 'sqlite:///C:/full/path/to/sqlite.db'
\$config['db_dsnw'] = 'mysql://root:@localhost/roundcubemail';

// ----------------------------------
// IMAP
// ----------------------------------
// The mail host chosen to perform the log-in.
// Leave blank to show a textbox at login, give a list of hosts
// to display a pulldown menu or set one host as string.
// To use SSL/TLS connection, enter hostname with prefix ssl:// or tls://
// Supported replacement variables:
// %n - hostname (\$_SERVER['SERVER_NAME'])
// %t - hostname without the first part
// %d - domain (http hostname \$_SERVER['HTTP_HOST'] without the first part)
// %s - domain name after the '@' from e-mail address provided at login screen
// For example %n = mail.domain.tld, %t = domain.tld
// WARNING: After hostname change update of mail_host column in users table is
//          required to match old user data records with the new host.
\$config['default_host'] = 'localhost';

// provide an URL where a user can get support for this Roundcube installation
// PLEASE DO NOT LINK TO THE ROUNDCUBE.NET WEBSITE HERE!
\$config['support_url'] = '';

// This key is used for encrypting purposes, like storing of imap password
// in the session. For historical reasons it's called DES_key, but it's used
// with any configured cipher_method (see below).
\$config['des_key'] = 'GcvHPgZU3ul6iF9SL080CBwm';

// Name your service. This is displayed on the login screen and in the window title
\$config['product_name'] = 'Roundcube Webmail - Vagrant';

// ----------------------------------
// PLUGINS
// ----------------------------------
// List of active plugins (in plugins/ directory)
\$config['plugins'] = array();

// Set the spell checking engine. Possible values:
// - 'googie'  - the default (also used for connecting to Nox Spell Server, see 'spellcheck_uri' setting)
// - 'pspell'  - requires the PHP Pspell module and aspell installed
// - 'enchant' - requires the PHP Enchant module
// - 'atd'     - install your own After the Deadline server or check with the people at http://www.afterthedeadline.com before using their API
// Since Google shut down their public spell checking service, the default settings
// connect to http://spell.roundcube.net which is a hosted service provided by Roundcube.
// You can connect to any other googie-compliant service by setting 'spellcheck_uri' accordingly.
\$config['spellcheck_engine'] = 'pspell';
EOF
)

echo "$ROUNDCUBECONFIG" > /home/vagrant/roundcubemail-1.2.0/config/config.inc.php

# set up the database
mysql -u root -e "CREATE DATABASE IF NOT EXISTS roundcubemail"
mysql -u root roundcubemail < /home/vagrant/roundcubemail-1.2.0/SQL/mysql.initial.sql
#add the vagrant user
mysql -u root < /vagrant/.scripts/roundcubemail-user-init.sql

else

echo "=================================================="
echo "ROUNDCUBE WEBMAIL ALREADY INSTALLED, SKIPPING"
echo "=================================================="

fi



if [ ! -d /home/vagrant/phpmyadmin-master ]; then

echo "=================================================="
echo "INSTALLING PHPMYADMIN"
echo "=================================================="
wget --quiet https://github.com/phpmyadmin/phpmyadmin/archive/master.zip -O /home/vagrant/phpmyadmin-master.zip
unzip /home/vagrant/phpmyadmin-master.zip

PMACONFIG=$(cat <<EOF
<?php
\$cfg['Servers'][1]['auth_type'] = 'config';
\$cfg['Servers'][1]['host'] = 'localhost';
\$cfg['Servers'][1]['user'] = 'root';
\$cfg['Servers'][1]['password'] = '';
\$cfg['Servers'][1]['connect_type'] = 'tcp';
\$cfg['Servers'][1]['compress'] = false;
\$cfg['Servers'][1]['AllowNoPassword'] = true;
EOF
)

echo "$PMACONFIG" > /home/vagrant/phpmyadmin-master/config.inc.php

echo "=================================================="
echo "RUNNING COMPOSER FOR PHPMYADMIN"
echo "=================================================="

composer --quiet --working-dir=/home/vagrant/phpmyadmin-master install

else

echo "=================================================="
echo "PHPMYADMIN ALREADY INSTALLED, SKIPPING"
echo "=================================================="

fi

service apache2 restart

echo "=================================================="
echo "CREATING WORDPRESS DATABASE IF IT DOES NOT EXIST YET"
echo "=================================================="
mysql -u root -e "CREATE DATABASE IF NOT EXISTS wordpress"
mysql -u root -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost'"
mysql -u root -e "FLUSH PRIVILEGES"



if [ ! -f /etc/postfix/main.cf ]; then

echo "=================================================="
echo "INSTALLING MAIL SERVER AND CONFIGURING"
echo "=================================================="

# install postfix
debconf-set-selections <<< "postfix postfix/mailname string ${HOSTNAME}"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt-get install -y postfix

# deliver to dovecot
echo "# dovecot configuration" >> /etc/postfix/main.cf
echo "virtual_alias_maps = hash:/etc/postfix/virtual" >> /etc/postfix/main.cf
echo "dovecot_destination_recipient_limit = 1" >> /etc/postfix/main.cf

# make sure all email goes to vagrant
echo "" >> /etc/postfix/main.cf
echo "# send all non-local email to vagrant" >> /etc/postfix/main.cf
echo "transport_maps = hash:/etc/postfix/transport" >> /etc/postfix/main.cf
echo "luser_relay = vagrant" >> /etc/postfix/main.cf
echo "localhost :" >> /etc/postfix/transport
echo "* local:vagrant" >> /etc/postfix/transport

# setup catch-all
echo "/.*@.*/ vagrant@localhost" > /etc/postfix/virtual

# generate databases
postmap /etc/postfix/virtual
postmap /etc/postfix/transport

# connect dovecot and postfix
echo 'dovecot   unix  -       n       n       -       -       pipe' >> /etc/postfix/master.cf
echo -e "\tflags=DRhu user=vmail:vmail argv=/usr/lib/dovecot/deliver" >> /etc/postfix/master.cf
echo -e "\t-f \${sender} -d \${recipient}" /etc/postfix/master.cf >> /etc/postfix/master.cf

# install dovecot
apt-get install -y dovecot-imapd

# configure dovecot to auto-create the trash folder
sed -i '/#mail_plugins = $mail_plugins/c\    mail_plugins = $mail_plugins autocreate' /etc/dovecot/conf.d/20-imap.conf

#restart dovecot
service dovecot restart

#send the welcome email
sendmail -t < /vagrant/.scripts/welcomemail

else

echo "=================================================="
echo "MAIL SERVER IS ALREADY INSTALLED, SKIPPING"
echo "=================================================="

fi

ln -s /vagrant/.scripts /home/vagrant/scripts

echo "=================================================="
echo "============= INSTALLATION COMPLETE =============="
echo "=================================================="
echo ""
echo "$(cat /vagrant/.scripts/finished.txt)"