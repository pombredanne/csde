# Needed for the Chef script to function properly
default[:setup][:deployment] = "11x"    # Choices are "07x", or "08x"

# Advanced Cassandra settings
default[:internal][:prime] = true

# true | false
default[:cassandra][:single_region] = "dummy"

# =============================================== #
# Configuration via Cassandra YAML (cassandra.yaml)
# =============================================== #

# :::::::::::::::::::::: #
# should NOT be changed! #
# :::::::::::::::::::::: #
default[:cassandra][:conf_path] = "/etc/cassandra/"

# It is best to have the commit log and the data
# directory on two seperate drives
default[:cassandra][:commitlog_dir] = "/var/lib"
default[:cassandra][:data_dir] = "/var/lib"

# A unique name is preferred to stop the risk of different clusters joining each other
default[:cassandra][:cluster_name] = "Cassandra Cluster"

# Ec2Snitch | Ec2MultRegionSnitch
# default[:cassandra][:endpoint_snitch] = "dummy"

# for each node there is a unique token
# will be passed by the node itself
default[:cassandra][:initial_token] = "dummy" 

# will be passed by the node itself
default[:cassandra][:seeds] = "dummy"

# not change
default[:cassandra][:rpc_address] = "0.0.0.0"

# :::::::::::::::::::::: #
# CAN be changed! #
# :::::::::::::::::::::: #

# RandomPartitioner | ByteOrderedPartitioner
# will be passed by KCSDB Server
default[:cassandra][:partitioner] = "RandomPartitioner"

# ============================================= #
# Configuration via Cassandra CLI (cassandra-cli)
# ============================================= #

# :::::::::::::::::::::: #
# should NOT be changed! #
# :::::::::::::::::::::: #

# the script for cassandra-cli
default[:cassandra][:configure_file] = "/home/ubuntu/configure.txt"

# placement strategy, used to place replicas in each region
# not change!
default[:cassandra][:placement_strategy] = "NetworkTopologyStrategy"

# default values, not change
# habe to be matched with YCSB configurations
default[:cassandra][:keyspace] = "usertable"
default[:cassandra][:column_family] = "data"

# :::::::::::::::::::::: #
# CAN be changed! #
# :::::::::::::::::::::: #

# replication factor for each region
# will be passed by KCSDB Server
# e.g 3, 3
# PRIMARY, has to be set!
default[:cassandra][:replication_factor] = "dummy"
