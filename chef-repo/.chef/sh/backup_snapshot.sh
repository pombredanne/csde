#!/usr/bin/env bash

# $1: 1st parameter, index of cassandra node for the snapshot

index=$1

echo "::: Installing pbzip2 via apt-get..."
sudo apt-get update -qq
sudo apt-get install pbzip2 -qq

echo "::: Installing s3cmd from S3..."
wget https://s3.amazonaws.com/kcsdb-init/s3cmd-1.1.0-beta3.tar.gz --output-document /home/ubuntu/s3cmd-1.1.0-beta3.tar.gz --quiet
tar -xf /home/ubuntu/s3cmd-1.1.0-beta3.tar.gz

echo "::: Stopping Cassandra node..."
sudo service cassandra stop

echo "::: Changing user for Cassandra folder..."
sudo chown -R ubuntu /var/lib/cassandra

echo "::: Clearing all commit log files..."
rm -f /var/lib/cassandra/commitlog/*.log 

echo "::: Downloading the snapshot tarball 'cas-snap-$index.tar.bz2' from S3..."
echo "DOWNLOADING START TIME:"
date
#/home/ubuntu/s3cmd-1.1.0-beta3/./s3cmd get s3://kcsdb-init/cas-snap-$index.tar.bz2 --no-progress --no-check-md5 --no-encrypt --no-guess-mime-type
/home/ubuntu/s3cmd-1.1.0-beta3/./s3cmd get s3://kcsdb-init/test-cas-snap-$index.tar.bz2 --no-progress --no-check-md5 --no-encrypt --no-guess-mime-type
echo "DOWNLOADING END TIME:"
date

echo "::: Decompressing the tarball 'cas-snap-$index.tar.bz2'..."
echo "DECOMPRESSING START TIME:"
date
#tar -xf cas-snap-$index.tar.bz2 -I /usr/bin/pbzip2
tar -xf test-cas-snap-$index.tar.bz2 -I /usr/bin/pbzip2
echo "DECOMPRESSING END TIME:"
date

echo "::: Moving the db files into Cassandra folder..."
mv /home/ubuntu/var/lib/cassandra/data/usertable/data/snapshots/cassandra-snapshot/*db /var/lib/cassandra/data/usertable/data/

echo "::: Changing user back to cassandra..."
sudo chown -R cassandra /var/lib/cassandra

echo "::: Restarting Cassandra node..."
sudo service cassandra start