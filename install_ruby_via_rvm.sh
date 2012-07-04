#!/usr/bin/env bash

update_apt_get(){
	sudo apt-get update -y
	sudo apt-get install openjdk-6-jdk build-essential openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison subversion -y
}

install_rvm(){
	curl -L https://get.rvm.io | bash -s stable
	source "$HOME/.rvm/scripts/rvm"
	rvm install 1.9.3
	rvm --default use 1.9.3
}

update_apt_get
install_rvm