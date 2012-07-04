#!/usr/bin/env bash
#set -e
#set -x

default_rubygems_version="1.8.24"
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
	echo "::: Updating apt-get..."
	apt-get update -qq # only relevant info in stdout
  apt-get upgrade -qq
}

install_packages_via_apt_get(){
	echo "::: Installing needed packages..."
  apt-get install nodejs wget ssl-cert openjdk-6-jdk ruby1.9.1-full libsqlite3-dev libopenssl-ruby libxslt-dev libxml2-dev -qq
  #gem install rubygems-update --no-ri --no-rdoc
  #update_rubygems
}

build_rubygems() {
  # Download and extract the source
  (cd /tmp && wget http://production.cf.rubygems.org/rubygems/rubygems-${default_rubygems_version}.tgz)
  (cd /tmp && tar xfz rubygems-${default_rubygems_version}.tgz)

  # Setup and install
  (cd /tmp/rubygems-${default_rubygems_version} && ruby setup.rb --no-format-executable)

  # Clean up the source artifacts
  rm -rf /tmp/rubygems-${default_rubygems_version}*
}

install_needed_gems(){
	echo "::: Installing needed gems..."
	gem install bundler -v '1.1.4' --no-ri --no-rdoc
	bundle update
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
#update_apt_get
#install_packages_via_apt_get
#build_rubygems
#install_needed_gems
build_chef_solo_config
run_chef_solo
#make_state_file
#bye