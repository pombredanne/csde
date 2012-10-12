#!/usr/bin/env bash

# $1: the IP address of OpsCenter Server (KCSDB Server as well)

echo "::: Unpacking the OpsCenter tarball file..."
tar xf /home/ubuntu/agent.tar.gz

echo "::: Installing OpsCenter Agent..."
(cd /home/ubuntu/agent && bin/install_agent.sh opscenter-agent.deb $1)
