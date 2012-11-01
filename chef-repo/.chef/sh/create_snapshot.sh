#!/usr/bin/env bash

# $1: 1st parameter, index of cassandra node for the snapshot

index=$1

echo "::: Installing s3cmd..."
wget https://s3.amazonaws.com/kcsdb-init/s3cmd-1.1.0-beta3.tar.gz --output-document /home/ubuntu/s3cmd-1.1.0-beta3.tar.gz --quiet
tar xf /home/ubuntu/s3cmd-1.1.0-beta3.tar.gz

#echo "::: Installing fog library..."
#sudo apt-get install libxml2-dev libxslt-dev -qq
#sudo gem install fog --no-ri --no-rdoc -v '1.6.0'

echo "::: Creating snapshot..."
nodetool -h localhost -p 7199 snapshot usertable -cf data -t cassandra-snapshot

#echo "::: Creating archive tar ball of this snapshot"
#sudo tar -zcpf cassandra-snapshot.tar.gz /var/lib/cassandra/data/usertable/data/snapshots/cassandra-snapshot

echo "::: Uploading all files to bucket 'kcsdb-init' in folder 'cassandra-$index'"
sudo /home/ubuntu/s3cmd-1.1.0-beta3/./s3cmd put /var/lib/cassandra/data/usertable/data/snapshots/cassandra-snapshot/* s3://kcsdb-init/cassandra-$index/