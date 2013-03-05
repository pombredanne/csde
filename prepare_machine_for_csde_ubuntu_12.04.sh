#!/usr/bin/env bash

welcome(){
	echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
	echo "::: THIS SCRIPT WILL INSTALL EVERYTHING TO MAKE THIS MACHINE READY FOR KCSDB"
	echo "::: PLEASE WAIT IF YOU THINK THE PROGRAM IS SLOW, IT IS WORKING IN THE BACKGROUND :)"
	echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
}

apt_update(){
	echo "::::::::::::::::::::::"
	echo "::: Update Apt Repo..." 
	echo "::::::::::::::::::::::"
	sudo apt-get update -qq
}

install_needed_packages(){
	echo "::::::::::::::::::::::::::::::::"
	echo "::: Installing needed packages.."
	echo "::::::::::::::::::::::::::::::::"
	sudo apt-get install openjdk-6-jdk nodejs build-essential openssl libreadline6 libreadline6-dev curl git-core \
											 zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev \
											 autoconf libc6-dev ncurses-dev automake libtool bison subversion pkg-config -qq
}

install_opscenter(){
	echo ":::::::::::::::::::::::::::"
	echo "::: Installing OpsCenter..."
	echo ":::::::::::::::::::::::::::"
	echo 'deb http://debian.datastax.com/community stable main' | sudo tee -a /etc/apt/sources.list # add repo
	curl -L http://debian.datastax.com/debian/repo_key -s | sudo apt-key add - # add key
	sudo apt-get update -qq # update repo
	sudo apt-get install opscenter-free -qq # install opscenter
}

install_gmetad(){
	echo "::::::::::::::::::::::::::::::::::::::::::::::::::::"
	echo "::: Installing Gmetad..."
	echo "::: [INFO] Always accept 'yes' for every question!!!"
	echo "::::::::::::::::::::::::::::::::::::::::::::::::::::"
	sudo apt-get install ganglia-webfrontend -qq				
	sudo cp /etc/ganglia-webfrontend/apache.conf /etc/apache2/sites-enabled
}

install_jruby(){
	echo "::::::::::::::::::::::::::::::::::::::::::::"
	echo "::: Installing JRuby [1.7.0] via tar ball..."
	echo "::::::::::::::::::::::::::::::::::::::::::::"
	wget https://s3.amazonaws.com/kcsdb-init/jruby-bin-1.7.0.tar.gz --output-document /home/ubuntu/jruby-bin-1.7.0.tar.gz --quiet
	tar xf /home/ubuntu/jruby-bin-1.7.0.tar.gz
	echo 'export JRUBY_HOME=/home/ubuntu/jruby-1.7.0' | tee -a $HOME/.bashrc
	echo 'PATH=$PATH:$JRUBY_HOME/bin' | tee -a $HOME/.bashrc
}

install_ruby(){
	echo "::::::::::::::::::::::::::::::::::::::"
	echo "::: Installing Ruby [1.9.3] via RVM..."
	echo "::::::::::::::::::::::::::::::::::::::"
	curl -L https://get.rvm.io -s | bash -s stable # load the install bash script
		
	# update rvm variables
	echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # This loads RVM into a shell session.' >> $HOME/.bashrc
	source "$HOME/.rvm/scripts/rvm"
	
	command rvm install 1.9.3 # rvm is NOT loaded into shell as a function
	
	echo ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
	echo "::: [INFO] Do NOT forget to set ruby 1.9.3 as default use"
	echo "::: [INFO] $ source $HOME/.bashrc"
	echo "::: [INFO] $ rvm --default use 1.9.3"
	echo ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
}

# ================================================================

# Time measurement
start=$(date +%s)

welcome
apt_update
install_needed_packages
#install_opscenter
#install_gmetad
install_jruby
install_ruby

echo ":::::::::::::::::::::::::::::::::::::::::"
echo "::: MACHINE IS READY FOR INSTALLING KCSDB"
echo "::: Open JDK 6"
echo "::: Ruby 1.9.3"
#echo "::: OpsCenter 2.1.2"
#echo "::: Gmetad"
echo ":::::::::::::::::::::::::::::::::::::::::"

# Time measurement
end=$(date +%s)

diff=$(( $end - $start ))

echo ":::::::::::::::::::::::::::::::::"
echo "::: Elapsed Time: $diff seconds!!"
echo ":::::::::::::::::::::::::::::::::"