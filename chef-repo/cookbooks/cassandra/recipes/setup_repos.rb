# Configure RAID0
execute 'sudo apt-get update -qq'
execute 'export DEBIAN_FRONTEND=noninteractive'
execute 'sudo apt-get install mdadm xfsprogs -qq'
execute 'curl -L https://s3.amazonaws.com/kcsdb-init/configure_devices_as_RAID0.sh -o $HOME/configure_devices_as_RAID0.sh'
execute 'sudo sh $HOME/configure_devices_as_RAID0.sh -m "/dev/md0" -d "/dev/xvdb /dev/xvdc"'
execute 'sudo blockdev --setra 65536 /dev/md0'
execute 'sudo mkfs.xfs -f /dev/md0'
execute 'sudo mount -t xfs -o noatime /dev/md0 /mnt'
execute 'sudo mkdir -p /mnt/cassandra/log'
execute 'sudo mkdir -p /mnt/cassandra/lib'
execute 'sudo ln -s /mnt/cassandra/log /var/log'
execute 'sudo ln -s /mnt/cassandra/ib /var/lib'


# Install DataStax Cassandra
execute 'echo "deb http://debian.datastax.com/community stable main" | sudo -E tee -a /etc/apt/sources.list'
execute 'curl -L http://debian.datastax.com/debian/repo_key | sudo apt-key add -'
execute 'sudo apt-get update -qq'
execute 'sudo apt-get install python-cql dsc1.1 -qq'
execute 'sudo service cassandra stop'

