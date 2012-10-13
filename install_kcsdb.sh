#!/usr/bin/env bash

#bootstrap_tar_url="http://s3.amazonaws.com/chef-solo/bootstrap-latest.tar.gz"
bootstrap_tar_url="https://s3.amazonaws.com/kcsdb-init/chef_10.12.0_bootstrap.tar.gz"

welcome(){
	echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
	echo "::: KIT Cloud Serving Deployment and Benchmark welcomes you :) :::"
	echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
}

pause(){
   read -p "$*"
}

configure_opscenter(){
	echo "::::::::::::::::::::::::::::"
	echo "::: Configuring OpsCenter..."
	echo "::::::::::::::::::::::::::::"
	
	# private IP of this machine, NOT public IP
	kcsdb=$(curl -L http://169.254.169.254/latest/meta-data/local-ipv4 -s)
	sudo sed -i 's/interface = .*/interface = '$kcsdb'/g' /etc/opscenter/opscenterd.conf
	
	# don't use SSL
	echo '[agents]' | sudo tee -a etc/opscenter/opscenterd.conf
	echo 'use_ssl = false' | sudo tee -a etc/opscenter/opscenterd.conf
	
	sudo service opscenterd restart
}

install_kcsdb(){
	echo ":::::::::::::::::::::::"
	echo "::: Installing KCSDB..."
	echo ":::::::::::::::::::::::"
	git clone https://github.com/lehoanganh/kcsdb.git
	(cd $HOME/kcsdb && bundle update)
	cp $HOME/kcsdb/chef-repo/.chef/conf/state.tmpl.yml $HOME/kcsdb/chef-repo/.chef/conf/state.yml
}

build_chef_solo_config() {
	echo "::::::::::::::::::::::::::::::::::::::::::::"
	echo "::: Building configurations for chef-solo..."
  	echo "::::::::::::::::::::::::::::::::::::::::::::"
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
	echo ":::::::::::::::::::::::::::::::::::::::::::::::"
	echo "::: Running chef-solo to install chef-server..."
	echo ":::::::::::::::::::::::::::::::::::::::::::::::"
	chef-solo -c /etc/chef/solo.rb -j /etc/chef/bootstrap.json -r $bootstrap_tar_url
}

start_chef_server(){
	# -d: detach from console
	
	echo ":::::::::::::::::::::::::::::"
	echo "::: Starting Chef Expander..."
	echo ":::::::::::::::::::::::::::::"
	chef-expander -d -n1

	echo ":::::::::::::::::::::::::"
	echo "::: Starting Chef Solr..."
	echo ":::::::::::::::::::::::::"
	chef-solr -d

	echo ":::::::::::::::::::::::::::"
	echo "::: Starting Chef Server..."
	echo ":::::::::::::::::::::::::::"
	chef-server -d

	echo ":::::::::::::::::::::::::::::::::"
	echo "::: Starting Chef Server WebUI..."
	echo ":::::::::::::::::::::::::::::::::"
	chef-server-webui -d
}

upload_cookbooks(){
	echo ":::::::::::::::::::::::::::::::::::::::::"
	echo "::: Uploading cookbooks to chef-server..."
	echo ":::::::::::::::::::::::::::::::::::::::::"
	knife cookbook upload --all --config /home/ubuntu/kcsdb/chef-repo/.chef/conf/knife.rb
}

upload_roles(){
	echo ":::::::::::::::::::::::::::::::::::::"
	echo "::: Uploading roles to chef-server..."
	echo ":::::::::::::::::::::::::::::::::::::"
	knife role from file /home/ubuntu/kcsdb/chef-repo/roles/cassandra.json --config /home/ubuntu/kcsdb/chef-repo/.chef/conf/knife.rb	
}

no_strict_host_key_checking(){
	echo ":::::::::::::::::::::::::::::::::::::::::::::::::::::"
	echo "::: No strict host key checking in ssh connections..."
	echo ":::::::::::::::::::::::::::::::::::::::::::::::::::::"
	mkdir -p /home/ubuntu/.ssh
	echo -e "Host *\n\tStrictHostKeyChecking no" > /home/ubuntu/.ssh/config
}

bye(){
	echo ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
	echo "::: KCSDB installed successfully!!! Please run 'bash start.sh' in 'kcsdb' home folder to start KCSDB Server :::"
	echo "::: KCSDB Server     --> [IP]:3000"
	echo "::: OpsCenter Server --> [IP]:8888"
	echo "::: Gmetad Server    --> [IP]:8651"
	echo ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
}

# ================================================================

# Time measurement
start=$(date +%s)

welcome
#pause 'Press [Enter] key to install KCSDB...'
configure_opscenter
install_kcsdb
build_chef_solo_config
run_chef_solo
start_chef_server
upload_cookbooks
#upload_roles
#no_strict_host_key_checking
bye

# Time measurement
end=$(date +%s)

diff=$(( $end - $start ))

echo ":::::::::::::::::::::::::::::::::"
echo "::: Elapsed Time: $diff seconds!!"
echo ":::::::::::::::::::::::::::::::::"