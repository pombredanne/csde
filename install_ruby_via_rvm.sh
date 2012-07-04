#!/usr/bin/env bash


	sudo apt-get update -y
	sudo apt-get install openjdk-6-jdk build-essential openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison subversion -y



	# load the install bash script
	curl -L https://get.rvm.io | bash -s stable
	
	# update rvm variables
	source "$HOME/.rvm/scripts/rvm"
	
	# prevent that rvm is loaded as a FUNCTION
	command rvm install 1.9.3
	
	# set ruby 1.9.3 as default use
	rvm --default use 1.9.3


