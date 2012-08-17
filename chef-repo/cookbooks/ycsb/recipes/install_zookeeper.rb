# ====================================== #
# @author: lha | me(at)lehoanganh(dot)de #
# ====================================== #

# the recipe is used to install ZooKeeper on each Cassandra's node
# ZooKeeper is responsible to coordinate many YCSB clients within a cluster
# to generate a workload together on a SUT

# step 1: download the tar ball
execute "echo 'Downloading the ZooKeeper tar ball from AWS S3...'"
execute "wget https://s3.amazonaws.com/kcsdb-lehoanganh/zookeeper-3.3.6.tar.gz -O $HOME/zk.tar.gz"

# step 2: create an empty folder for ZooKeeper
execute "echo 'Creating an empty folder for ZooKeeper: $HOME/zk...'"
execute "mkdir -p $HOME/zk"

# step 3: extract the ZooKeeper tar ball into the folder
execute "echo 'Extracting the ZooKeeper tar ball into the folder...'"
execute "tar -xf $HOME/zk.tar.gz --strip-components=1 -C $HOME/zk"

# step 4: move zoo.cfg into ZooKeeper folder
execute "echo 'Moving zoo.cfg into ZooKeeper folder...'"
execute "mv $HOME/zoo.cfg $HOME/zk/conf"

# step 5: move myid into ZooKeeper folder
execute "echo 'Moving myid into ZooKeeper fodler...'"
execute "mv $HOME/myid $HOME/zk"

# step 6: start ZooKeeper
execute "echo 'Starting ZooKeeper Server...'"
execute "sudo $HOME/zk/bin/./zkServer.sh start"