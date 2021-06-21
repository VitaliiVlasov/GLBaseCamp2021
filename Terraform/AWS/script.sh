#!/bin/bash

apt -y update
apt -y install apache2
MY_IP=`curl https://ifconfig.me`
echo "WebServer with IP: $MY_IP Build by Terraform!" > /var/www/html/index.html