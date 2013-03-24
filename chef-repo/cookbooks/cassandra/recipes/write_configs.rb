# create data directory
# create log directory
execute "sudo mkdir -p #{node[:cassandra][:data_dir]}"
execute "sudo mkdir -p #{node[:cassandra][:commitlog_dir]}"
execute "sudo chown -R #{node[:internal][:package_user]}:#{node[:internal][:package_user]} #{node[:cassandra][:data_dir]}"
execute "sudo chown -R #{node[:internal][:package_user]}:#{node[:internal][:package_user]} #{node[:cassandra][:commitlog_dir]}"

# read the token.txt which is passed by CSDE Server to this node
# update node[:cassandra][:initial_token] attribute
# will be used later to overwrite cassandra.yaml
ruby_block "read_tokens" do
  block do
    home_user = nil
    if node[:cassandra][:os] == 'ubuntu'
      home_user = 'ubuntu'
    else
      home_user = 'idcuser'
    end
    File.open("/home/#{home_user}/token.txt","r").each do |line| 
      node.set[:cassandra][:initial_token] = line.to_s.strip
    end
    File.open("/home/#{home_user}/seeds.txt","r").each do |line| 
      node.set[:cassandra][:seeds] = line.to_s.strip
    end
  end
  action :create
end

# overwrite cassandra-env.sh
# cassandra-env.sh

# update: JVM_OPTS
# update: MAX_HEAP_SIZE (if needed)
# update: HEAP_NEWSIZE (if needed)
ruby_block "build_cassandra_env" do
  block do
    filename = node[:cassandra][:conf_path] + "cassandra-env.sh"
    cassandra_env = File.read filename

    if node[:cassandra][:os] == 'ubuntu'
      cassandra_env.gsub!(/# JVM_OPTS="\$JVM_OPTS -Djava.rmi.server.hostname=<public name>"/, "JVM_OPTS=\"\$JVM_OPTS -Djava.rmi.server.hostname=#{node[:cloud][:private_ips].first}\"")
    else
      cassandra_env.gsub!(/# JVM_OPTS="\$JVM_OPTS -Djava.rmi.server.hostname=<public name>"/, "JVM_OPTS=\"\$JVM_OPTS -Djava.rmi.server.hostname=#{node[:cloud][:public_ips].first}\"")  
    end
    
    if node[:cassandra][:heap_size] != "dummy" then cassandra_env.gsub!(/#MAX_HEAP_SIZE=.*/, "MAX_HEAP_SIZE=\"#{node[:cassandra][:heap_size]}M\"") end
    if node[:cassandra][:heap_new_size] != "dummy" then cassandra_env.gsub!(/#HEAP_NEWSIZE=.*/, "HEAP_NEWSIZE=\"#{node[:cassandra][:heap_new_size]}M\"") end
    File.open(filename,'w'){|f| f.write cassandra_env }
  end
  action :create
  #notifies :run, resources(:execute => "clear-data"), :immediately
end

# overwrite cassandra.yaml
# cassandra.yaml
ruby_block "build_cassandra_yaml" do
  block do
    filename = node[:cassandra][:conf_path] + "cassandra.yaml"
    cassandra_yaml = File.read filename

    cassandra_yaml.gsub!(/\/.*\/cassandra\/data/,               "#{node[:cassandra][:data_dir]}/cassandra/data")
    cassandra_yaml.gsub!(/\/.*\/cassandra\/commitlog/,          "#{node[:cassandra][:commitlog_dir]}/cassandra/commitlog")
    cassandra_yaml.gsub!(/\/.*\/cassandra\/saved_caches/,       "#{node[:cassandra][:data_dir]}/cassandra/saved_caches")
    cassandra_yaml.gsub!(/cluster_name:.*/,                     "cluster_name: '#{node[:cassandra][:cluster_name]}'")
    cassandra_yaml.gsub!(/rpc_address:.*/,                      "rpc_address: #{node[:cassandra][:rpc_address]}")
    cassandra_yaml.gsub!(/initial_token:.*/,                    "initial_token: #{node[:cassandra][:initial_token]}")
    cassandra_yaml.gsub!(/seeds:.*/,                            "seeds: \"#{node[:cassandra][:seeds]}\"")
    cassandra_yaml.gsub!(/partitioner:.*/,                      "partitioner: org.apache.cassandra.dht.#{node[:cassandra][:partitioner]}")    
    
    if node[:cassandra][:os] == 'ubuntu'
      cassandra_yaml.gsub!(/listen_address:.*/,                   "listen_address: #{node[:cloud][:private_ips].first}")
      if node[:cassandra][:single_region] == 'true' # single region
        cassandra_yaml.gsub!(/endpoint_snitch:.*/,                "endpoint_snitch: org.apache.cassandra.locator.Ec2Snitch")
        cassandra_yaml.gsub!(/# broadcast_address:.*/,            "broadcast_address: #{node[:cloud][:private_ips].first}")
      else # multiple regions
        cassandra_yaml.gsub!(/endpoint_snitch:.*/,                "endpoint_snitch: org.apache.cassandra.locator.Ec2MultiRegionSnitch")
        cassandra_yaml.gsub!(/# broadcast_address:.*/,            "broadcast_address: #{node[:cloud][:public_ips].first}")
      end
    elsif node[:cassandra][:os] == 'redhat'
      cassandra_yaml.gsub!(/listen_address:.*/,                   "listen_address: #{node[:cloud][:public_ips].first}")
      cassandra_yaml.gsub!(/endpoint_snitch:.*/,                "endpoint_snitch: org.apache.cassandra.locator.RackInferringSnitch")
      cassandra_yaml.gsub!(/# broadcast_address:.*/,            "broadcast_address: #{node[:cloud][:public_ips].first}")
    end
    
    cassandra_yaml.gsub!(/key_cache_size_in_mb:.*/,             "key_cache_size_in_mb: #{node[:cassandra][:key_cache_size_in_mb]}")    
    cassandra_yaml.gsub!(/key_cache_save_period:.*/,            "key_cache_save_period: #{node[:cassandra][:key_cache_save_period]}")
    cassandra_yaml.gsub!(/row_cache_size_in_mb:.*/,             "row_cache_size_in_mb: #{node[:cassandra][:row_cache_size_in_mb]}")
    cassandra_yaml.gsub!(/row_cache_save_period:.*/,            "row_cache_save_period: #{node[:cassandra][:row_cache_save_period]}")
    cassandra_yaml.gsub!(/row_cache_provider:.*/,               "row_cache_provider: #{node[:cassandra][:row_cache_provider]}")
    
    cassandra_yaml.gsub!(/column_index_size_in_kb:.*/,          "column_index_size_in_kb: #{node[:cassandra][:column_index_size_in_kb]}")
    cassandra_yaml.gsub!(/commitlog_sync:.*/,                   "commitlog_sync: #{node[:cassandra][:commitlog_sync]}")
    cassandra_yaml.gsub!(/commitlog_sync_period_in_ms:.*/,      "commitlog_sync_period_in_ms: #{node[:cassandra][:commitlog_sync_period_in_ms]}")
    cassandra_yaml.gsub!(/# commitlog_total_space_in_mb:.*/,    "commitlog_total_space_in_mb: #{node[:cassandra][:commitlog_total_space_in_mb]}")
    cassandra_yaml.gsub!(/compaction_preheat_key_cache:.*/,     "compaction_preheat_key_cache: #{node[:cassandra][:compaction_preheat_key_cache]}")
    cassandra_yaml.gsub!(/compaction_throughput_mb_per_sec:.*/, "compaction_throughput_mb_per_sec: #{node[:cassandra][:compaction_throughput_mb_per_sec]}")
    cassandra_yaml.gsub!(/#concurrent_compactors:.*/,           "concurrent_compactors: #{node[:cassandra][:concurrent_compactors]}")
    cassandra_yaml.gsub!(/concurrent_reads:.*/,                 "concurrent_reads: #{node[:cassandra][:concurrent_reads]}")
    cassandra_yaml.gsub!(/concurrent_writes:.*/,                "concurrent_writes: #{node[:cassandra][:concurrent_writes]}")
    cassandra_yaml.gsub!(/flush_largest_memtables_at:.*/,       "flush_largest_memtables_at: #{node[:cassandra][:flush_largest_memtables_at]}")
    cassandra_yaml.gsub!(/in_memory_compaction_limit_in_mb:.*/, "in_memory_compaction_limit_in_mb: #{node[:cassandra][:in_memory_compaction_limit_in_mb]}")
    cassandra_yaml.gsub!(/index_interval:.*/,                   "index_interval: #{node[:cassandra][:index_interval]}")
    cassandra_yaml.gsub!(/memtable_flush_queue_size:.*/,        "memtable_flush_queue_size: #{node[:cassandra][:memtable_flush_queue_size]}")
    cassandra_yaml.gsub!(/#memtable_flush_writers:.*/,          "memtable_flush_writers: #{node[:cassandra][:memtable_flush_writers]}")
    cassandra_yaml.gsub!(/# memtable_total_space_in_mb:.*/,     "memtable_total_space_in_mb: #{node[:cassandra][:memtable_total_space_in_mb]}")
    cassandra_yaml.gsub!(/multithreaded_compaction:.*/,         "multithreaded_compaction: #{node[:cassandra][:multithreaded_compaction]}")
    cassandra_yaml.gsub!(/reduce_cache_sizes_at:.*/,            "reduce_cache_sizes_at: #{node[:cassandra][:reduce_cache_sizes_at]}")
    cassandra_yaml.gsub!(/reduce_cache_capacity_to:.*/,         "reduce_cache_capacity_to: #{node[:cassandra][:reduce_cache_capacity_to]}")
    
    File.open(filename,'w') {|f| f.write cassandra_yaml }
  end
  action :create
end