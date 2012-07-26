#
# Cookbook Name:: cassandra
# Recipe:: write_configs
#
# Copyright 2011, DataStax
#
# Apache License
#

###################################################
# 
# Write Configs and Start Services
# 
###################################################

# create data directory
# create log directory
execute "sudo mkdir -p #{node[:cassandra][:data_dir]}"
execute "sudo mkdir -p #{node[:cassandra][:commitlog_dir]}"
execute "sudo chown -R #{node[:internal][:package_user]}:#{node[:internal][:package_user]} #{node[:cassandra][:data_dir]}"
execute "sudo chown -R #{node[:internal][:package_user]}:#{node[:internal][:package_user]} #{node[:cassandra][:commitlog_dir]}"

# read the token.txt which is passed by KCSDB Server to this node
# update node[:cassandra][:initial_token] attribute
# will be used later to overwrite cassandra.yaml
ruby_block "read_tokens" do
  block do
    File.open("/home/ubuntu/token.txt","r").each do |line| 
      node[:cassandra][:initial_token] = line.to_s.strip
    end
    File.open("/home/ubuntu/seeds.txt","r").each do |line| 
      node[:cassandra][:seeds] = line.to_s.strip
    end
  end
  action :create
end

# overwrite cassandra-env.sh
# cassandra-env.sh
ruby_block "build_cassandra_evn" do
  block do
    filename = node[:cassandra][:conf_path] + "cassandra-env.sh"
    cassandra_env = File.read filename
    cassandra_env = cassandra_env.gsub(/# JVM_OPTS="\$JVM_OPTS -Djava.rmi.server.hostname=<public name>"/, "JVM_OPTS=\"\$JVM_OPTS -Djava.rmi.server.hostname=#{node[:cloud][:private_ips].first}\"")
    File.open(filename,'w'){|f| f.write cassandra_env }
  end
  action :create
  notifies :run, resources(:execute => "clear-data"), :immediately
end

# overwrite cassandra.yaml
# cassandra.yaml
ruby_block "build_cassandra_yaml" do
  block do
    filename = node[:cassandra][:conf_path] + "cassandra.yaml"
    cassandra_yaml = File.read filename

    cassandra_yaml = cassandra_yaml.gsub(/\/.*\/cassandra\/data/,         "#{node[:cassandra][:data_dir]}/cassandra/data")
    cassandra_yaml = cassandra_yaml.gsub(/\/.*\/cassandra\/commitlog/,    "#{node[:cassandra][:commitlog_dir]}/cassandra/commitlog")
    cassandra_yaml = cassandra_yaml.gsub(/\/.*\/cassandra\/saved_caches/, "#{node[:cassandra][:data_dir]}/cassandra/saved_caches")
    cassandra_yaml = cassandra_yaml.gsub(/cluster_name:.*/,               "cluster_name: '#{node[:cassandra][:cluster_name]}'")
    cassandra_yaml = cassandra_yaml.gsub(/rpc_address:.*/,                "rpc_address: 0.0.0.0")
    cassandra_yaml = cassandra_yaml.gsub(/initial_token:.*/,              "initial_token: #{node[:cassandra][:initial_token]}")
    cassandra_yaml = cassandra_yaml.gsub(/seeds:.*/,                      "seeds: \"#{node[:cassandra][:seeds]}\"")
    cassandra_yaml = cassandra_yaml.gsub(/listen_address:.*/,             "listen_address: #{node[:cloud][:private_ips].first}")    
    
    if node[:cassandra][:single_region] # single region
      cassandra_yaml = cassandra_yaml.gsub(/endpoint_snitch:.*/,           "endpoint_snitch: Ec2Snitch")
      cassandra_yaml = cassandra_yaml.gsub(/# broadcast_address:.*/,       "broadcast_address: #{node[:cloud][:private_ips].first}")
    else # multiple regions
      cassandra_yaml = cassandra_yaml.gsub(/endpoint_snitch:.*/,           "endpoint_snitch: Ec2MultRegionSnitch")
      cassandra_yaml = cassandra_yaml.gsub(/# broadcast_address:.*/,       "broadcast_address: #{node[:cloud][:public_ips].first}")
    end
    
    File.open(filename,'w') {|f| f.write cassandra_yaml }
  end
  action :create
end