#!/usr/bin/env bash
# 

welcome(){
	echo "--------------------------------------------------------------------------------------------------"
	echo "this script is used to install needed packages in order to prepare a machine for CSDE server"
	echo "image is Red Hat Enterprise Linux 6.3"
	echo "following softwares will be installed:"
	echo "1. Oracle JDK 6"
	echo "2. Ruby 1.9.3"
	echo "3. several packages"
	echo "--------------------------------------------------------------------------------------------------"
}

yum_update(){
	echo "---------------------------------"
	echo "Updating all existing packages..."
	echo "---------------------------------"
	sudo yum update -y
}

install_needed_packages(){
	echo "-----------------------------"
	echo "Installing needed packages..."
	echo "-----------------------------"
	sudo yum install jna bash curl git gcc-c++ patch readline readline-devel zlib zlib-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison iconv-devel -y
}

install_oracle_jdk_6(){
	echo "--------------------------"
	echo "Installing Oracle JDK 6..."
	echo "--------------------------"
	
	# load the iso file and install
	curl -L https://s3.amazonaws.com/csde/jdk-6u41-linux-x64-rpm.bin -o $HOME/jdk-6u41-linux-x64-rpm.bin
	chmod u+x jdk-6u41-linux-x64-rpm.bin
	sudo $HOME/./jdk-6u41-linux-x64-rpm.bin
	
	# update java alternatives
	sudo alternatives --install /usr/bin/java java /usr/java/jdk1.6.0_41/jre/bin/java 20000
	sudo alternatives --install /usr/bin/javaws javaws /usr/java/jdk1.6.0_41/jre/bin/javaws 20000
	sudo alternatives --install /usr/bin/javac javac /usr/java/jdk1.6.0_41/bin/javac 20000
	sudo alternatives --install /usr/bin/jar jar /usr/java/jdk1.6.0_41/bin/jar 20000
}

install_ruby(){
	echo "------------------------"
	echo "Installing Ruby 1.9.3..."
	echo "------------------------"
	
	# load the install bash script
	curl -L https://get.rvm.io -s | bash -s stable
	
	# update RVM variables	
	echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # This loads RVM into a shell session.' >>$HOME/.bashrc
	source $HOME/.bashrc
	source $HOME/.rvm/scripts/rvm
	
	command rvm install 1.9.3 # rvm is NOT loaded into shell as a function
	
	echo ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
	echo "::: [INFO] Do NOT forget to set ruby 1.9.3 as default use"
	echo "::: [INFO] $ source $HOME/.bashrc"
	echo "::: [INFO] $ rvm --default use 1.9.3"
	echo ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
}
