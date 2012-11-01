#!/usr/bin/env bash

# $1: 1st parameter, index of cassandra node for the snapshot
# $2: 2nd parameter, AWS Access Key ID
# $3: 3rd parameter, AWS Secret Access Key

index=$1
aws_access_key_id=$2
aws_secret_access_key=$3

echo "::: Installing s3cmd..."
wget https://s3.amazonaws.com/kcsdb-init/s3cmd-1.1.0-beta3.tar.gz --output-document /home/ubuntu/s3cmd-1.1.0-beta3.tar.gz --quiet
tar xf /home/ubuntu/s3cmd-1.1.0-beta3.tar.gz
wget https://s3.amazonaws.com/kcsdb-init/s3cfg_tmpl --output-document /home/ubuntu/.s3cfg --quiet
sed -i 's/access_key = dummy/access_key = '$aws_access_key_id'/g' /home/ubuntu/.s3cfg
sed -i 's/secret_key = dummy/secret_key = '$aws_secret_access_key'/g' /home/ubuntu/.s3cfg

echo "::: Stopping Cassandra node..."
sudo /etc/init.d/cassandra stop

echo "::: Changing user for cassandra folder..."
sudo chown -R ubuntu /var/lib/cassandra

echo "::: Clearing all commit log files..."
rm -f /var/lib/cassandra/commitlog/*.log 

echo "::: Downloading the tar ball backup file from S3..."
#wget https://s3.amazonaws.com/kcsdb-init/cassandra-$1.tar.gz --output-document /home/ubuntu/cassandra-snapshot.tar.gz --quiet
/home/ubuntu/s3cmd-1.1.0-beta3/./s3cmd get s3://kcsdb-init/cassandra-$index.tar.gz

echo "::: Extracting the tar ball..."
tar xf /home/ubuntu/cassandra-$index.tar.gz

echo ":: Moving the db files into Cassandra folder..."
mv /home/ubuntu/var/lib/cassandra/data/usertable/data/snapshots/cassandra-snapshot/* /var/lib/cassandra/data/usertable/data/

echo "::: Changing user back to cassandra..."
sudo chown -R cassandra /var/lib/cassandra

echo "::: Restarting Cassandra node..."
sudo /etc/init.d/cassandra start