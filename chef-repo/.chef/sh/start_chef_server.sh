#!/usr/bin/env bash
set -e
set -x

# @author: Le Hoang Anh | me[at]lehoanganh[dot]de
#
# --- DESCRIPTION ---
# The shell script is used to configure a Chef-Server on EC2 machine
# by starting process. This script will add a new user "chef" in vhost "/chef"
# in RabbitMQ

# -d: detach from console

#echo "::: Starting Chef Expander..."
#chef-expander -d -n1

echo "::: Starting Chef Solr..."
chef-solr -d

echo "::: Starting Chef Server..."
chef-server -d

echo "::: Starting Chef Server WebUI..."
chef-server-webui -d

# fixed already in chef 10.12.0??
#echo "::: Setting up the RabbitMQ queue..."
#rabbitmqctl add_vhost /chef
#rabbitmqctl add_user chef testing
#rabbitmqctl set_permissions -p /chef chef ".*" ".*" ".*"