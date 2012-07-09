#!/usr/bin/env bash

# update apt-get
sudo apt-get update -y

# install needed packages
sudo apt-get install nodejs openjdk-6-jdk build-essential openssl libreadline6 libreadline6-dev curl git-core \
										 zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev \
										 autoconf libc6-dev ncurses-dev automake libtool bison subversion -y

# load the install bash script
curl -L https://get.rvm.io | bash -s stable
	
# update rvm variables
echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm" # This loads RVM into a shell session.' >> $HOME/.bashrc
. "$HOME/.rvm/scripts/rvm"

# rvm is NOT loaded into shell as a function
command rvm install 1.9.3

# do NOT forget to set ruby 1.9.3 as default use
# rvm --default use 1.9.3