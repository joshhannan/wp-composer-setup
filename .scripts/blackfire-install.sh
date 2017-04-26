#!/usr/bin/env bash

#add the key for the blackfire.io repo
wget -O - https://packagecloud.io/gpg.key | sudo apt-key add -

#add the repo
echo "deb http://packages.blackfire.io/debian any main" | sudo tee /etc/apt/sources.list.d/blackfire.list

#update repo list
sudo apt-get update

#install the blackfire agent
sudo apt-get install blackfire-agent

echo "==================================================="
echo "=          BLACKFIRE AGENT INSTALLED              ="
echo "==================================================="
echo "= You will need to enter your SERVER credentials  ="
echo "= which can be obtained by visiting blackfire.io  ="
echo "= and navigating to your account page.            ="
echo "==================================================="

#prompt user for credentials
sudo blackfire-agent -register

#restart agent to load new credentials
sudo /etc/init.d/blackfire-agent restart

#installing php probe
sudo apt-get install blackfire-php

#restart apache
sudo service apache2 restart