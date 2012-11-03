#!/usr/bin/env bash

# $1: 1st parameter, index of cassandra node for the snapshot

index=$1

#echo "::: Installing pbzip2..."
#sudo apt-get update -qq
#sudo apt-get install pbzip2 -qq

echo "::: Installing s3cmd..."
#wget https://s3.amazonaws.com/kcsdb-init/s3cmd-1.1.0-beta3.tar.gz --output-document /home/ubuntu/s3cmd-1.1.0-beta3.tar.gz --quiet
#tar xf /home/ubuntu/s3cmd-1.1.0-beta3.tar.gz
sudo apt-get update -qq
sudo apt-get install s3cmd -qq

echo "::: Stopping Cassandra node..."
sudo /etc/init.d/cassandra stop

echo "::: Changing user for cassandra folder..."
sudo chown -R ubuntu /var/lib/cassandra

echo "::: Clearing all commit log files..."
rm -f /var/lib/cassandra/commitlog/*.log 

#echo "::: Downloading backup snapshot from S3..."
#/home/ubuntu/s3cmd-1.1.0-beta3/./s3cmd get s3://kcsdb-init/cas-snap-$index.tar.bz2

echo "::: Downloading backup files from bucket 'kcsdb-init' in folder 'cas-$index'"
mkdir -p /home/ubuntu/temp
s3cmd get s3://kcsdb-init/cas-$index/* /home/ubuntu/temp --no-progress --no-check-md5 --no-encrypt

#echo "::: Extracting backup snapshot..."
#pbzip2 -dc cas-snap-$index.tar.bz2 | tar -x

echo ":: Moving the db files into Cassandra folder..."
#mv /home/ubuntu/var/lib/cassandra/data/usertable/data/snapshots/cassandra-snapshot/*db /var/lib/cassandra/data/usertable/data/
mv /home/ubuntu/temp/* /var/lib/cassandra/data/usertable/data/

echo "::: Changing user back to cassandra..."
sudo chown -R cassandra /var/lib/cassandra

echo "::: Restarting Cassandra node..."
sudo /etc/init.d/cassandra start