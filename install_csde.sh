#!/usr/bin/env bash

bootstrap_tar_url="http://s3.amazonaws.com/chef-solo/bootstrap-latest.tar.gz"
#bootstrap_tar_url="https://s3.amazonaws.com/kcsdb-init/chef_10.12.0_bootstrap.tar.gz"

welcome(){
	echo "------------------------------------------------------------------"
	echo "Cloud System Deployment and Experiment (CSDE) Tool welcomes you :)"
	echo "------------------------------------------------------------------"
}

pause(){
   read -p "$*"
}

install_csde(){
	echo "------------------"
	echo "Installing CSDE..."
	echo "------------------"
	git clone https://github.com/myownthemepark/csde.git
	(cd $HOME/csde && bundle update)
	cp $HOME/csde/chef-repo/.chef/conf/state.tmpl.yml $HOME/csde/chef-repo/.chef/conf/state.yml
}

configure_opscenter(){
	echo "------------------------"
	echo "Configuring OpsCenter..."
	echo "------------------------"
	
	# private IP of this machine, NOT public IP
	#csde=$(curl -L http://169.254.169.254/latest/meta-data/local-ipv4 -s)
	
	if grep -q "Ubuntu" /etc/*release
	then
		echo "-- Ubuntu detected!"
		sudo apt-get update -y
		csde=$(curl -L http://169.254.169.254/latest/meta-data/local-ipv4 -s)
		sudo sed -i 's/interface = .*/interface = '$csde'/g' /etc/opscenter/opscenterd.conf
		sudo sed -i 's/os: .*/os: ubuntu/g' $HOME/csde/chef-repo/.chef/conf/state.yml	
	else
		echo "-- Red Hat detected!"
		csde=$(ifconfig eth0 | grep "inet " | awk -F: '{print $2}' | awk '{print $1}')
		sudo sed -i 's/interface = .*/interface = '$csde'/g' /etc/opscenter/opscenterd.conf
		sudo sed -i 's/os: .*/os: redhat/g' $HOME/csde/chef-repo/.chef/conf/state.yml
	fi
	
	# don't use SSL
	echo '[agents]' | sudo tee -a /etc/opscenter/opscenterd.conf
	echo 'use_ssl = false' | sudo tee -a /etc/opscenter/opscenterd.conf
	
	sudo service opscenterd restart
}

build_chef_solo_config() {
	echo "----------------------------------------"
	echo "Building configurations for chef-solo..."
	echo "----------------------------------------"

	echo "-- create folder /etc/chef"
	sudo mkdir -p /etc/chef

	echo "-- create file solo.rb in /etc/chef"
	sudo touch /etc/chef/solo.rb
	echo "file_cache_path '/tmp/chef-solo'" | sudo tee -a /etc/chef/solo.rb
	echo "cookbook_path   '/tmp/chef-solo/cookbooks'" | sudo tee -a /etc/chef/solo.rb

#	cat > /etc/chef/solo.rb <<SOLO_RB
#file_cache_path "/tmp/chef-solo"
#cookbook_path   "/tmp/chef-solo/cookbooks"
#SOLO_RB

	echo "-- create file bootstrap.json in /etc/chef"
	sudo touch /etc/chef/bootstrap.json
	echo "{" | sudo tee -a /etc/chef/bootstrap.json
	echo "	'chef_server' : {" | sudo tee -a /etc/chef/bootstrap.json
	echo "		'server_url': 'http://localhost:4000'," | sudo tee -a /etc/chef/bootstrap.json
	echo "		'webui_enabled' : true" | sudo tee -a /etc/chef/bootstrap.json
	echo "	}," | sudo tee -a /etc/chef/bootstrap.json
	echo "	'run_list': [ 'recipe[chef-server::rubygems-install]' ]" | sudo tee -a /etc/chef/bootstrap.json
	echo "}" | sudo tee -a /etc/chef/bootstrap.json
	
# cat > /etc/chef/bootstrap.json <<BOOTSTRAP_JSON
#{
#  "chef_server" : {
#	"server_url": "http://localhost:4000",  
#    "webui_enabled" : true
#  },
#  "run_list": [ "recipe[chef-server::rubygems-install]" ]
#}
#BOOTSTRAP_JSON

}

run_chef_solo(){
	echo "--------------------------------------------"
	echo ":Running chef-solo to install chef-server..."
	echo "--------------------------------------------"
	chef-solo -c /etc/chef/solo.rb -j /etc/chef/bootstrap.json -r $bootstrap_tar_url
}

start_chef_server(){
	# -d: detach from console
	
	echo "-------------------------"
	echo "Starting Chef Expander..."
	echo "-------------------------"
	chef-expander -d -n1

	echo "---------------------"
	echo "Starting Chef Solr..."
	echo "---------------------"
	chef-solr -d

	echo "-----------------------"
	echo "Starting Chef Server..."
	echo "-----------------------"
	chef-server -d

	echo "-----------------------------"
	echo "Starting Chef Server WebUI..."
	echo "-----------------------------"
	chef-server-webui -d
}

upload_cookbooks(){
	echo "-------------------------------------"
	echo "Uploading cookbooks to Chef Server..."
	echo "-------------------------------------"
	knife cookbook upload --all --config $HOME/csde/chef-repo/.chef/conf/knife.rb
}

upload_roles(){
	echo ":::::::::::::::::::::::::::::::::::::"
	echo "::: Uploading roles to chef-server..."
	echo ":::::::::::::::::::::::::::::::::::::"
	knife role from file $HOME/csde/chef-repo/roles/cassandra.json --config $HOME/csde/chef-repo/.chef/conf/knife.rb	
}

no_strict_host_key_checking(){
	echo ":::::::::::::::::::::::::::::::::::::::::::::::::::::"
	echo "::: No strict host key checking in ssh connections..."
	echo ":::::::::::::::::::::::::::::::::::::::::::::::::::::"
	mkdir -p $HOME/.ssh
	echo -e "Host *\n\tStrictHostKeyChecking no" > $HOME/.ssh/config
}

bye(){
	echo "-----------------------------------------------------------------------"
	echo "CSDE installed successfully!!!"
	echo "Execute 'source $HOME/.bashrc to load environment variables"
	echo "Then execute 'bash start.sh' in 'csde' home folder to start CSDE Server"
	echo "CSDE Server      --> [IP]:3000"
	echo "Chef Server      --> [IP]:4040"
	echo "OpsCenter Server --> [IP]:8888"
	#echo "Gmetad Server    --> [IP]:8651"
	echo "-----------------------------------------------------------------------"
}

# ================================================================

# Time measurement
start=$(date +%s)

welcome
#pause 'Press [Enter] key to install KCSDB...'
install_csde
configure_opscenter
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
