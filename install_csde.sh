#!/usr/bin/env bash

bootstrap_tar_url="http://s3.amazonaws.com/chef-solo/bootstrap-latest.tar.gz"
#bootstrap_tar_url="https://s3.amazonaws.com/csde/chef_10.12.0_bootstrap.tar.gz"

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
	
	if grep -q "Ubuntu" /etc/*release
	then
		# bugfix, rabbitmq server can not start after installing in RHEL 6
		# cause another process 'qpidd' has already taken the port 5672
		# http://blog.servergrove.com/2012/04/25/how-to-fix-kernel-pid-terminated-when-starting-rabbitmq/
		ps aux | grep -e 'qpidd' | grep -v grep | awk '{print $2}' | xargs -i sudo kill {}
	
		(cd /home/ubuntu/csde && bundle update)
		cp /home/ubuntu/csde/chef-repo/.chef/conf/state.tmpl.yml /home/ubuntu/csde/chef-repo/.chef/conf/state.yml	
	else
		(cd /home/idcuser/csde && bundle update)
		cp /home/idcuser/csde/chef-repo/.chef/conf/state.tmpl.yml /home/idcuser/csde/chef-repo/.chef/conf/state.yml	
	fi
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
		apt-get update -y
		csde=$(curl -L http://169.254.169.254/latest/meta-data/local-ipv4 -s)
		sed -i 's/interface = .*/interface = '$csde'/g' /etc/opscenter/opscenterd.conf
		sed -i 's/os: .*/os: ubuntu/g' /home/ubuntu/csde/chef-repo/.chef/conf/state.yml	
	else
		echo "-- Red Hat detected!"
		yum update -y
		csde=$(ifconfig eth0 | grep "inet " | awk -F: '{print $2}' | awk '{print $1}')
		sed -i 's/interface = .*/interface = '$csde'/g' /etc/opscenter/opscenterd.conf
		sed -i 's/os: .*/os: redhat/g' /home/idcuser/csde/chef-repo/.chef/conf/state.yml
	fi
	
	# don't use SSL
	echo '[agents]' | sudo tee -a /etc/opscenter/opscenterd.conf
	echo 'use_ssl = false' | sudo tee -a /etc/opscenter/opscenterd.conf
	
	service opscenterd restart
}

build_chef_solo_config() {
	echo "----------------------------------------"
	echo "Building configurations for chef-solo..."
	echo "----------------------------------------"

	echo "-- create folder /etc/chef"
	mkdir -p /etc/chef

	echo "-- create file solo.rb in /etc/chef"
	touch /etc/chef/solo.rb
	echo "file_cache_path '/tmp/chef-solo'" | tee -a /etc/chef/solo.rb
	echo "cookbook_path   '/tmp/chef-solo/cookbooks'" | tee -a /etc/chef/solo.rb

#	cat > /etc/chef/solo.rb <<SOLO_RB
#file_cache_path "/tmp/chef-solo"
#cookbook_path   "/tmp/chef-solo/cookbooks"
#SOLO_RB

	echo "-- create file bootstrap.json in /etc/chef"
	touch /etc/chef/bootstrap.json
	echo "{" | tee -a /etc/chef/bootstrap.json
	echo "	\"chef_server\" : {" | tee -a /etc/chef/bootstrap.json
	echo "		\"server_url\": \"http://localhost:4000\"," | tee -a /etc/chef/bootstrap.json
	echo "		\"webui_enabled\" : true" | tee -a /etc/chef/bootstrap.json
	echo "	}," | tee -a /etc/chef/bootstrap.json
	echo "	\"run_list\": [ \"recipe[chef-server::rubygems-install]\" ]" | tee -a /etc/chef/bootstrap.json
	echo "}" | tee -a /etc/chef/bootstrap.json
	
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
	if grep -q "Ubuntu" /etc/*release
	then
		knife cookbook upload --all --config /home/ubuntu/csde/chef-repo/.chef/conf/knife.rb
	else
		knife cookbook upload --all --config /home/idcuser/csde/chef-repo/.chef/conf/knife.rb
	fi
}

upload_roles(){
	echo ":::::::::::::::::::::::::::::::::::::"
	echo "::: Uploading roles to chef-server..."
	echo ":::::::::::::::::::::::::::::::::::::"
	if grep -q "Ubuntu" /etc/*release
	then
		knife role from file /home/ubuntu/csde/chef-repo/roles/cassandra.json --config $HOME/csde/chef-repo/.chef/conf/knife.rb		
	else
		knife role from file /home/idcuser/csde/chef-repo/roles/cassandra.json --config $HOME/csde/chef-repo/.chef/conf/knife.rb		
	fi
}

no_strict_host_key_checking(){
	echo ":::::::::::::::::::::::::::::::::::::::::::::::::::::"
	echo "::: No strict host key checking in ssh connections..."
	echo ":::::::::::::::::::::::::::::::::::::::::::::::::::::"
	if grep -q "Ubuntu" /etc/*release
	then
		mkdir -p /home/ubuntu/.ssh
		echo -e "Host *\n\tStrictHostKeyChecking no" > /home/ubuntu/.ssh/config	
	else
		mkdir -p /home/idcuser/.ssh
		echo -e "Host *\n\tStrictHostKeyChecking no" > /home/idcuser/.ssh/config	
	fi
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
