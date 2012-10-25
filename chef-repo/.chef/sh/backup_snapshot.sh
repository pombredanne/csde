#!/usr/bin/env bash

# $1: 1st parameter, index of cassandra node for the snapshot

index=$1

echo "::: Stopping Cassandra node..."
sudo /etc/init.d/cassandra stop

echo "::: Changing user for cassandra folder..."
sudo chown -R ubuntu /var/lib/cassandra

echo "::: Clearing all commit log files..."
rm -f /var/lib/cassandra/commitlog/*.log 

echo "::: Clearing all db files..."
rm /var/lib/cassandra/data/usertable/data/*.db

echo "::: Downloading the tar ball backup file from S3..."
wget https://s3.amazonaws.com/kcsdb-init/cassandra-$1.tar.gz --output-document /home/ubuntu/cassandra-snapshot.tar.gz

echo "::Extracting the tar ball..."
tar xf /home/ubuntu/cassandra-snapshot.tar.gz

echo ":: Copying the db files into Cassandra folder..."
cp /home/ubuntu/home/ubuntu/cassandra-snapshot/* /var/lib/cassandra/data/usertable/data/

echo "::: Changing user back to cassandra..."
sudo chown -R cassandra /var/lib/cassandra

echo "::: Restarting Cassandra node..."
sudo /etc/init.d/cassandra start