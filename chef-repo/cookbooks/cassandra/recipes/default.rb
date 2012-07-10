#
# Cookbook Name:: cassandra
# Recipe:: default
#
# Copyright 2011, DataStax
#
# Apache License
#

###################################################
# 
# Public Variable Declarations
# 
###################################################

# Stop Cassandra if it is running.
# Different for Debian due to service package.
#if node[:platform] == "debian"
#  service "cassandra" do
#    action :stop
#    ignore_failure true
#  end
#else
#  service "cassandra" do
#    action :stop
#  end
#end

# Only for debug purposes
OPTIONAL_INSTALL = false 

include_recipe "cassandra::setup_repos"

# using java recipe for the node and comment this 
#include_recipe "cassandra::required_packages"
#
# instead user java recipe.

#node["java"]["install_flavor"] = "oracle"
#node["java"]["install_flavor"] = "openjdk"
#include_recipe "java" 

# LHA
# java recipe is not needed anymore
# in order to save time, an ready AMI (Java and co.) is used to bootstrap

if OPTIONAL_INSTALL
  include_recipe "cassandra::optional_packages"
end

include_recipe "cassandra::additional_settings"
include_recipe "cassandra::install"