#
# Cookbook Name:: cassandra
# Recipe:: additional_settings
#
# Copyright 2011, DataStax
#
# Apache License
#

###################################################
# 
# Additional Settings
# 
###################################################

execute "rm -rf /etc/motd"
execute "touch /etc/motd"
execute 'echo "export JAVA_HOME=/usr/lib/jvm/java-6-sun" | sudo -E tee -a ~/.bashrc'
execute 'echo "export JAVA_HOME=/usr/lib/jvm/java-6-sun" | sudo -E tee -a ~/.profile'
execute 'sudo bash -c "ulimit -n 32768"'
execute 'echo "* soft nofile 32768" | sudo tee -a /etc/security/limits.conf'
execute 'echo "* hard nofile 32768" | sudo tee -a /etc/security/limits.conf'
execute 'sync'
execute 'echo 3 > /proc/sys/vm/drop_caches'
