# Install DataStax Cassandra
execute 'sudo apt-get update -qq'
execute 'echo "deb http://debian.datastax.com/community stable main" | sudo -E tee -a /etc/apt/sources.list'
execute 'curl -L http://debian.datastax.com/debian/repo_key | sudo apt-key add -'
execute 'sudo apt-get update -qq'
execute 'sudo apt-get install python-cql dsc1.1 -qq'
execute 'sudo service cassandra stop'

# Configure RAID0

# image has mdadm and xfsprogs already
#execute 'sudo DEBIAN_FRONTEND=noninteractive apt-get install mdadm xfsprogs -qq'

execute 'curl -L https://s3.amazonaws.com/kcsdb-init/configure_devices_as_RAID0.sh -o $HOME/configure_devices_as_RAID0.sh'
execute 'sudo sh $HOME/configure_devices_as_RAID0.sh -m "/dev/md0" -d "/dev/xvdb /dev/xvdc"'
#execute 'sudo blockdev --setra 65536 /dev/md0'
execute 'sudo mkfs.xfs -f /dev/md0'
execute 'sudo mount -t xfs -o noatime /dev/md0 /mnt'


# Remove and recreate cassandra directories.
execute 'sudo rm -rf /var/log/cassandra'
execute 'sudo rm -rf /var/lib/cassandra'
execute 'sudo mkdir -p /mnt/var/lib/cassandra'
execute 'sudo mkdir -p /mnt/var/log/cassandra'

# Create links to cassandra log and lib dirs.
execute 'sudo ln -s /mnt/var/log/cassandra /var/log'
execute 'sudo ln -s /mnt/var/lib/cassandra /var/lib'

# Make data, commitlog, and cache dirs.
execute 'sudo mkdir -p /mnt/var/lib/cassandra/data'
execute 'sudo mkdir -p /mnt/var/lib/cassandra/commitlog'
execute 'sudo mkdir -p /mnt/var/lib/cassandra/saved_caches'

# Set access rights.
execute 'sudo chown -R cassandra:cassandra /var/lib/cassandra'
execute 'sudo chown -R cassandra:cassandra /var/log/cassandra'
execute 'sudo chown -R cassandra:cassandra /mnt/var/lib/cassandra'
execute 'sudo chown -R cassandra:cassandra /mnt/var/log/cassandra'

execute 'sudo chmod -R 777 /var/lib/cassandra'
execute 'sudo chmod -R 777 /var/log/cassandra'
execute 'sudo chmod -R 777 /mnt/var/lib/cassandra'
execute 'sudo chmod -R 777 /mnt/var/log/cassandra'