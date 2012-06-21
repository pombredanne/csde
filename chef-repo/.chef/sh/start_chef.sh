#!/usr/bin/env bash
set -e
set -x

# @author: Le Hoang Anh | me[at]lehoanganh[dot]de
#
# --- DESCRIPTION ---
# The shell script is used to configure a Chef-Server on EC2 machine
# by starting process. This script will add a new user "chef" in vhost "/chef"
# in RabbitMQ

/etc/init.d/chef-server start
rabbitmqctl add_vhost /chef
rabbitmqctl add_user chef kcsd
rabbitmqctl set_permissions -p /chef chef '.*' '.*' '.*'