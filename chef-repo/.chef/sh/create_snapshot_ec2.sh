#!/usr/bin/env bash

echo "::: Creating snapshot files of Cassandra..."
nodetool -h localhost -p 7199 snapshot usertable -cf data -t cassandra-snapshot

echo "::: Moving all snapshot data from RAID0 disks to EBS store"
sudo mv /var/lib/cassandra/data/usertable/data/snapshots/cassandra-snapshot/ /home/ubuntu/