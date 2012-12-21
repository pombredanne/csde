#!/usr/bin/env bash

echo "::: Creating snapshot files of Cassandra..."
nodetool -h localhost -p 7199 snapshot usertable -cf data -t cassandra-snapshot

echo "::: Stopping Cassandra node..."
sudo service cassandra stop

echo "::: Changing user for Cassandra folder..."
sudo chown -R ubuntu /var/lib/cassandra

echo "::: Moving all snapshot data from RAID0 disks to EBS store"
mv /var/lib/cassandra/data/usertable/data/snapshots/cassandra-snapshot/ /home/ubuntu

echo "::: Changing user back to cassandra for Cassandra folder..."
sudo chown -R cassandra /var/lib/cassandra

echo "::: Restarting Cassandra node..."
sudo service cassandra start