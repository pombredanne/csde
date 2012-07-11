#
# Cookbook Name:: cassandra
# Recipe:: install
#
# Copyright 2011, DataStax
#
# Apache License
#

###################################################
# 
# Install Cassandra
# 
###################################################

# Used to clear any system information that may have
# been created when the service autostarts
execute "clear-data" do
  command "rm -rf /var/lib/cassandra/data/system"
  action :nothing
end

# Sets up a user to own the data directories
node[:internal][:package_user] = "cassandra"

package "cassandra" do
  notifies :run, resources(:execute => "clear-data"), :immediately
end

service "cassandra" do 
  # supports :status => true, :restart => true, :reload => true
  supports :status => true, :restart => true, :reload => true, :stop => true, :start => true
  # action [ :enable, :start ]
  action [ :enable, :stop ]
end

# Test
# execute "token" do
  # command "echo #{node[:token_dummy]} > $HOME/token.txt"
  # action :nothing
# end

# execute "echo #{node['token_dummy'].inspect} > $HOME/token.txt"
execute "echo #{node[:tags][:tokendummy]} > $HOME/token.txt"
