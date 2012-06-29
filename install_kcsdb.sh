#!/usr/bin/env bash
#set -e
#set -x

bootstrap_tar_url="http://s3.amazonaws.com/chef-solo/bootstrap-latest.tar.gz"

welcome(){
	echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
	echo "::: KIT Cloud Serving Deployment and Benchmark welcomes you :) :::"
	echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
}

pause(){
   read -p "$*"
}

update_apt_get(){
	apt-get update -qq # only relevant info in stdout
  apt-get upgrade -qq
}

install_packages_via_apt_get(){
  apt-get install nodejs wget ssl-cert openjdk-6-jdk rubygems ruby1.9.1-full libsqlite3-dev libopenssl-ruby libxslt-dev libxml2-dev -qq
  gem install rubygems-update --no-ri --no-rdoc
  update_rubygems
}

install_needed_gems(){
	gem install bundler -v '1.1.4' --no-ri --no-rdoc
	bundle update
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

run_chef_solo(){
	chef-solo -c /etc/chef/solo.rb -j /etc/chef/bootstrap.json -r $bootstrap_tar_url
}

make_state_file(){
	cp chef-repo/.chef/conf/state.tmpl.yml chef-repo/.chef/conf/state.yml
}
bye(){
	echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
	echo "::: KCSDB installed successfully!!! Please run 'rails server' in 'kcsdb' home folder to start KCSDB Server :::"
	echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
}
welcome
pause 'Press [Enter] key to install KCSDB...'
update_apt_get
install_packages_via_apt_get
install_needed_gems
build_chef_solo_config
run_chef_solo
make_state_file
bye