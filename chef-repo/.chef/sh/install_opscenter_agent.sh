#!/usr/bin/env bash

# $1: the IP address of OpsCenter Server (KCSDB Server as well)

echo "::: Unpacking the OpsCenter tarball file..."
tar xf /home/ubuntu/agent.tar.gz

echo "::: Installing OpsCenter Agent..."
(cd /home/ubuntu/agent && bin/install_agent.sh opscenter-agent.deb $1)

echo "::: Disabling SSL in OpsCenter Agent..."
echo 'use_ssl: 0' | tee -a /var/lib/opscenter-agent/conf/address.yaml

echo "::: Restarting OpsCenter Agent..."
sudo service opscenter-agent restart

echo "::: Restarting Cassandra..."
sudo service cassandra restart

