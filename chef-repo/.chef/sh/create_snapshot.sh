#!/usr/bin/env bash

# $1: 1st parameter, index of cassandra node for the snapshot
# $2: 2nd parameter, AWS Access Key ID
# $3: 3rd parameter, AWS Secret Access Key

index=$1
aws_access_key_id=$2
aws_secret_access_key=$3

echo "::: Installing fog library..."
sudo apt-get install libxml2-dev libxslt-dev -qq
sudo gem install fog --no-ri --no-rdoc

echo "::: Creating snapshot..."
nodetool -h localhost -p 7199 snapshot usertable -cf data -t cassandra-snapshot

echo "::: Copying snapshot folder to home folder..."
sudo cp -r /var/lib/cassandra/data/usertable/data/snapshots/cassandra-snapshot /home/ubuntu

echo "::: Creating archive tar ball of this snapshot..."
sudo tar -zcvpf cassandra-snapshot.tar.gz /home/ubuntu/cassandra-snapshot

echo "::: Creating a S3 upload Ruby script..."
(
cat <<EOF
require 'rubygems'
require 'fog'

# create a s3 fog object
s3 = Fog::Storage.new(
      provider: 'AWS',
      aws_access_key_id: '$aws_access_key_id',
      aws_secret_access_key: '$aws_secret_access_key',
      region: 'us-east-1'
)

# check if a bucket called 'kcsdb-init' already exists
dirs = s3.directories
check = false
dirs.each {|dir| if dir.key == "kcsdb-init" then check = true end}
      
# if this bucket does not exist than create a new one
kcsdb_init = nil
if ! check
	puts "Bucket 'kcsdb-init' does NOT exist, create a new one..."
    kcsdb_init = s3.directories.create(
    	:key => "kcsdb-init",
        :public => true
    )
else
    puts "Bucket 'kcsdb-init' EXIST, get the bucket..."
    kcsdb_init = s3.directories.get 'kcsdb-init'
end        

puts "Uploading snapshot cassandra-$index to S3..."
file = kcsdb_init.files.create(
	:key    => 'cassandra-$index.tar.gz',
    :body   => File.open("/home/ubuntu/cassandra-snapshot.tar.gz"),
    :public => true
)  

EOF
) > /home/ubuntu/upload_snapshot_to_s3.rb

echo "::: Executing the S3 upload Ruby script..."
ruby /home/ubuntu/upload_snapshot_to_s3.rb
