#!/usr/bin/env bash

welcome(){
	echo "----------------------------------------------------------------------------------------"
	echo "this script is used to install needed packages in order to cook an image for Chef Client"
	echo "image is Red Hat Enterprise Linux 6.3"
	echo "following softwares will be installed:"
	echo "1. Oracle JDK 6"
	echo "2. Ruby 1.9.3"
	echo "3. several packages"
	echo "----------------------------------------------------------------------------------------"
}

install_oracle_jdk_6(){
	echo "--------------------------"
	echo "Installing Oracle JDK 6..."
	echo "--------------------------"
	
	echo "-- load the iso file and install"
	curl -L https://s3.amazonaws.com/csde/jdk-6u41-linux-x64-rpm.bin -o $HOME/jdk-6u41-linux-x64-rpm.bin
	chmod 777 jdk-6u41-linux-x64-rpm.bin
	yes '' | sudo $HOME/./jdk-6u41-linux-x64-rpm.bin
	
	echo "-- update java alternatives"
	sudo alternatives --install /usr/bin/java java /usr/java/jdk1.6.0_41/jre/bin/java 20000
	sudo alternatives --install /usr/bin/javaws javaws /usr/java/jdk1.6.0_41/jre/bin/javaws 20000
	sudo alternatives --install /usr/bin/javac javac /usr/java/jdk1.6.0_41/bin/javac 20000
	sudo alternatives --install /usr/bin/jar jar /usr/java/jdk1.6.0_41/bin/jar 20000
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
	sudo yum install sqlite-devel jna bash curl git gcc-c++ patch readline readline-devel zlib zlib-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison iconv-devel -y
}

install_ruby_1.9.3(){
	echo "------------------------"
	echo "Installing Ruby 1.9.3..."
	echo "------------------------"
	
	echo "-- load the install bash script"
	curl -L https://get.rvm.io -s | bash -s stable
	
	echo "-- update RVM variables"	
	echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # This loads RVM into a shell session.' >>$HOME/.bashrc
	source $HOME/.bashrc
	
	echo "-- install Ruby 1.9.3"
	command rvm install 1.9.3 # rvm is NOT loaded into shell as a function
	
	echo "-----------------------------------------------------"
	echo "[INFO] Do NOT forget to set ruby 1.9.3 as default use"
	echo "[INFO] $ source $HOME/.bashrc"
	echo "[INFO] $ rvm --default use 1.9.3"
	echo "[INFO] $ gem install chef -v 10.24.0"
	echo "-----------------------------------------------------"
}

deactive_firewall(){
	echo "-------------------"
	echo "Deactiving firewall"
	echo "-------------------"
	sudo service iptables save
	sudo service iptables stop
	sudo chkconfig iptables off
}

# execution

# time measurement
start=$(date +%s)

welcome
install_oracle_jdk_6
yum_update
install_needed_packages
install_ruby_1.9.3
deactive_firewall

echo "--------------------------------------------------"
echo "Machine is ready for cooking image for Chef Client"
echo "Oracle JDK 6"
echo "Ruby 1.9.3"
echo "--------------------------------------------------"

# time measurement
end=$(date +%s)

diff=$(( $end - $start ))

echo ":::::::::::::::::::::::::::::::::"
echo "::: Elapsed Time: $diff seconds!!"
echo ":::::::::::::::::::::::::::::::::"
