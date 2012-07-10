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
