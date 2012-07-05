#!/usr/bin/env bash

bootstrap_tar_url="http://s3.amazonaws.com/chef-solo/bootstrap-latest.tar.gz"

welcome(){
	echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
	echo "::: KIT Cloud Serving Deployment and Benchmark welcomes you :) :::"
	echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
}

pause(){
   read -p "$*"
}

install_kcsdb(){
	echo "::: Installing KCSDB..."
	git clone https://github.com/lehoanganh/kcsdb.git
	(cd $HOME/kcsdb && bundle update)
	cp $HOME/kcsdb/chef-repo/.chef/conf/state.tmpl.yml $HOME/kcsdb/chef-repo/.chef/conf/state.yml
}

build_chef_solo_config() {
	echo "::: Building configurations for chef-solo..."
  mkdir -p /etc/chef

  cat > /etc/chef/solo.rb <<SOLO_RB| grep 
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

run_chef_solo(){
	echo "::: Running chef-solo to install chef-server..."
	chef-solo -c /etc/chef/solo.rb -j /etc/chef/bootstrap.json -r $bootstrap_tar_url
}

bye(){
	echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
	echo "::: KCSDB installed successfully!!! Please run 'rails server' in 'kcsdb' home folder to start KCSDB Server :::"
	echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
}

welcome
pause 'Press [Enter] key to install KCSDB...'
install_kcsdb
build_chef_solo_config
run_chef_solo
bye