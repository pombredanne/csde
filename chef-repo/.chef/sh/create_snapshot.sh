#!/usr/bin/env bash

# $1: 1st parameter, index of cassandra node for the snapshot

index=$1

echo "::: Installing s3cmd..."
wget https://s3.amazonaws.com/kcsdb-init/s3cmd-1.1.0-beta3.tar.gz --output-document /home/ubuntu/s3cmd-1.1.0-beta3.tar.gz --quiet
tar xf /home/ubuntu/s3cmd-1.1.0-beta3.tar.gz

echo "::: Creating snapshot..."
nodetool -h localhost -p 7199 snapshot usertable -cf data -t cassandra-snapshot

echo "::: Stopping Cassandra node..."
sudo /etc/init.d/cassandra stop

echo "::: Changing user for cassandra folder..."
sudo chown -R ubuntu /var/lib/cassandra

echo "::: Uploading all files to bucket 'kcsdb-init' in folder 'cassandra-$index'"
/home/ubuntu/s3cmd-1.1.0-beta3/./s3cmd put /var/lib/cassandra/data/usertable/data/snapshots/cassandra-snapshot/* s3://kcsdb-init/cassandra-$index/