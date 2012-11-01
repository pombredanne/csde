#!/usr/bin/env bash

# $1: 1st parameter, index of cassandra node for the snapshot

index=$1

echo "::: Installing s3cmd..."
wget https://s3.amazonaws.com/kcsdb-init/s3cmd-1.1.0-beta3.tar.gz --output-document /home/ubuntu/s3cmd-1.1.0-beta3.tar.gz --quiet
tar xf /home/ubuntu/s3cmd-1.1.0-beta3.tar.gz

echo "::: Stopping Cassandra node..."
sudo /etc/init.d/cassandra stop

echo "::: Changing user for cassandra folder..."
sudo chown -R ubuntu /var/lib/cassandra

echo "::: Clearing all commit log files..."
rm -f /var/lib/cassandra/commitlog/*.log 

echo "::: Downloading the tar ball backup file from S3..."
/home/ubuntu/s3cmd-1.1.0-beta3/./s3cmd get s3://kcsdb-init/cassandra-$index.tar.gz

echo "::: Extracting the tar ball..."
tar xf /home/ubuntu/cassandra-$index.tar.gz

echo ":: Moving the db files into Cassandra folder..."
mv /home/ubuntu/var/lib/cassandra/data/usertable/data/snapshots/cassandra-snapshot/* /var/lib/cassandra/data/usertable/data/

echo "::: Changing user back to cassandra..."
sudo chown -R cassandra /var/lib/cassandra

echo "::: Restarting Cassandra node..."
sudo /etc/init.d/cassandra start