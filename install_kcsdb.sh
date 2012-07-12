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

run_chef_solo(){
	echo "::: Running chef-solo to install chef-server..."
	chef-solo -c /etc/chef/solo.rb -j /etc/chef/bootstrap.json -r $bootstrap_tar_url
}

start_chef_server(){
	# -d: detach from console
	
	#echo "::: Starting Chef Expander..."
	#chef-expander -d -n1

	echo "::: Starting Chef Solr..."
	chef-solr -d

	echo "::: Starting Chef Server..."
	chef-server -d

	echo "::: Starting Chef Server WebUI..."
	chef-server-webui -d
}

upload_cookbooks(){
	echo "::: Uploading cookbooks to chef-server..."
	knife cookbook upload --all --config /home/ubuntu/kcsdb/chef-repo/.chef/conf/knife.rb
}

upload_roles(){
	echo "::: Uploading roles to chef-server..."
	knife role from file /home/ubuntu/kcsdb/chef-repo/roles/cassandra.json --config /home/ubuntu/kcsdb/chef-repo/.chef/conf/knife.rb	
}

no_strict_host_key_checking(){
	echo "::: No strict host key checking in ssh connections..."
	echo -e "Host *\n\tStrictHostKeyChecking no"
}

bye(){
	echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
	echo "::: KCSDB installed successfully!!! Please run 'rvmsudo rails server' in 'kcsdb' home folder to start KCSDB Server :::"
	echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
}

welcome
#pause 'Press [Enter] key to install KCSDB...'
install_kcsdb
build_chef_solo_config
run_chef_solo
start_chef_server
upload_cookbooks
upload_roles
no_strict_host_key_checking
bye