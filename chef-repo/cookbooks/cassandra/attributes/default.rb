# Needed for the Chef script to function properly
default[:setup][:deployment] = "11x" # Cassandra 1.1.5

# Advanced Cassandra settings
default[:internal][:prime] = true

# true | false
default[:cassandra][:single_region] = "dummy"

# the Gmond collector node among all Gmond nodes
default[:cassandra][:gmond_collector] = "dummy"

# OS
default[:cassandra][:os] = "dummy"

# =============================================== #
# Configuration via Cassandra YAML (cassandra.yaml)
# =============================================== #

# :::::::::::::::::::::: #
# should NOT be changed! #
# :::::::::::::::::::::: #
# TODO
# Check!
#default[:cassandra][:conf_path] = "/etc/cassandra/"
default[:cassandra][:conf_path] = "/etc/cassandra/conf/"

# It is best to have the commit log and the data
# directory on two separate drives
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

# not change
# TODO
default[:cassandra][:snitch] = "dummy"

# :::::::::::::::::::::: #
# CAN be changed! #
# :::::::::::::::::::::: #

# RandomPartitioner (NOT default in Cassandra 1.2)
# Murmur3Partitioner (DEFAULT in Cassandra 1.2)
# Each Partitioner has a different token range
# Please use a corresponding token generation mechanism
# see method calculate_token_position in benchmark controller
default[:cassandra][:partitioner] = "RandomPartitioner"

# ::::: #
# CACHE #
# ::::: #
default[:cassandra][:key_cache_size_in_mb] = " "
default[:cassandra][:key_cache_save_period] = "14400"
default[:cassandra][:row_cache_size_in_mb] = "0"
default[:cassandra][:row_cache_save_period] = "0"
default[:cassandra][:row_cache_provider] = "SerializingCacheProvider" # ConcurrentLinkedHashCacheProvider | SerializingCacheProvider

# ::::::::::::::::::::::::::::::::::::::::::: #
# PERFORMANCE TUNING: MEMTABLE and COMPACTION #
# ::::::::::::::::::::::::::::::::::::::::::: #
default[:cassandra][:column_index_size_in_kb] = "64"
default[:cassandra][:commitlog_sync] = "periodic"
default[:cassandra][:commitlog_sync_period_in_ms] = "10000"
default[:cassandra][:commitlog_total_space_in_mb] = "4096" # HAVE TO UNCOMMENT
default[:cassandra][:compaction_preheat_key_cache] = true
default[:cassandra][:compaction_throughput_mb_per_sec] = "16"
default[:cassandra][:concurrent_compactors] = "1" # HAVE TO UNCOMMENT
default[:cassandra][:concurrent_reads] = "32"
default[:cassandra][:concurrent_writes] = "32"
default[:cassandra][:flush_largest_memtables_at] = "0.75"
default[:cassandra][:in_memory_compaction_limit_in_mb] = "64"
default[:cassandra][:index_interval] = "128"
default[:cassandra][:memtable_flush_queue_size] = "4"
default[:cassandra][:memtable_flush_writers] = "1" # HAVE TO UNCOMMENT
default[:cassandra][:memtable_total_space_in_mb] = "2048" # HAVE TO UNCOMMENT
default[:cassandra][:multithreaded_compaction] = false
default[:cassandra][:reduce_cache_sizes_at] = "0.85"
default[:cassandra][:reduce_cache_capacity_to] = "0.6"

# =============================================== #
# Configuration via Cassandra ENV (cassandra-env.sh)
# =============================================== #
default[:cassandra][:heap_size] = "dummy"
default[:cassandra][:heap_new_size] = "dummy"


# ============================================= #
# Configuration via Cassandra CLI (cassandra-cli)
# ============================================= #

# :::::::::::::::::::::: #
# should NOT be changed! #
# :::::::::::::::::::::: #

# the script for cassandra-cli
# IBM SCE --> idcuser
# AWS EC2 --> ubuntu
default[:cassandra][:configure_file] = "/home/dummy/configure.txt"

# placement strategy, used to place replicas in each region
# not change!
default[:cassandra][:placement_strategy] = "NetworkTopologyStrategy"

# default values, not change
# have to be matched with YCSB configurations
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
