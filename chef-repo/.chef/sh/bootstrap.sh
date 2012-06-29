#!/usr/bin/env bash
set -e
set -x

# @author: Le Hoang Anh | me[at]lehoanganh[dot]de
#
# --- DESCRIPTION ---
# The bootstrap script is used to bootstrap a Chef-Server on EC2 machine
# by using rubygems, chef-solo and some cookbooks to install chef-server
#
# --- USING ---
# 1. Transfer this script into the machine you want to set up chef-server
# 2. Login to the machine via ssh
# 3. Execute
# sudo bash bootstrap.sh
#
# --- COPYRIGHT ---
#
# Originally from https://github.com/fnichol/wiki-notes/wiki/Deploying-Chef-Server-On-Amazon-EC2
# Some parameters and configurations are modified to use with KCSD
#
# Another sources
# http://wiki.opscode.com/display/ChefCN/Bootstrap+Chef+RubyGems+Installation
# http://wiki.opscode.com/display/chef/Chef+Configuration+Settings
# http://rubygems.org/pages/download
#
# --- SPECIFICATIONS ---
# Ubuntu 11.10. x64 (e.g. ami-4dad7424 from alestic.com). Only x64 works for Chef Server, x86 NOT
# Rubygems 1.8.24
# Chef 10.12.0
# 
# --- ATTENTION ---
# 1. If you change configurations and parameters below, the script may NOT work. 
# So, please do NOT! Just run it!
#
# 2. After setting up Chef Server sucessfully (hopefully :)), go to Chef Server Web UI
# in [chef-server-domain]:4040, login with username "admin" and password "p@ssw0rd1" 
#
# 3. Change the dummy password. Now!

# the two tar balls are assumed to be in $HOME folder
#not downloaded from rubygems.org and s3.amazonaws.com anymore

install_ruby_packages() {
  apt-get update -qq # only relevant info in stdout
	apt-get install openjdk-6-jdk libopenssl-ruby build-essential wget ssl-cert -qq # only relevant info in stdout
}

untar_bootstrap_cookbooks() {
	(cd $HOME && tar xf $HOME/bootstrap-10.12.0.tar.gz)
	mkdir -p /tmp/chef-solo
	mv $HOME/cookbooks /tmp/chef-solo
}

build_chef_solo_config() {
  mkdir -p /etc/chef

  cat > /etc/chef/solo.rb <<SOLO_RB
file_cache_path "/tmp/chef-solo"
cookbook_path   "/tmp/chef-solo/cookbooks"
SOLO_RB

  cat > /etc/chef/bootstrap.json <<BOOTSTRAP_JSON
{
  "chef_server" : {
	"server_url": "http://localhost:4000",  
    "webui_enabled" : true
  },
  "run_list": [ "recipe[chef-server::rubygems-install]" ]
}
BOOTSTRAP_JSON
}

run_chef_solo() {
  chef-solo -c /etc/chef/solo.rb -j /etc/chef/bootstrap.json
}

# Perform the actual bootstrap

install_ruby_packages

untar_bootstrap_cookbooks

build_chef_solo_config

run_chef_solo
