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

# if node[:java][:install_flavor] ==  "oracle" 
   # execute 'echo "export JAVA_HOME=/usr/lib/jvm/java-6-sun" | sudo -E tee -a ~/.bashrc'
   # execute 'echo "export JAVA_HOME=/usr/lib/jvm/java-6-sun" | sudo -E tee -a ~/.profile'
# end
# 
# if node[:java][:install_flavor] ==  "openjdk" 
   # execute 'echo "export JAVA_HOME=/usr/lib/jvm/java-1.6.0-openjdk" | sudo -E tee -a ~/.bashrc'
   # execute 'echo "export JAVA_HOME=/usr/lib/jvm/java-1.6.0-openjdk" | sudo -E tee -a ~/.profile'
# end

# LHA
# set JAVA_HOME for a ready AMI (java is already set up) of KCSDB
execute 'echo "export JAVA_HOME=/usr/lib/jvm/java-6-sun" | sudo -E tee -a ~/.bashrc'
execute 'echo "export JAVA_HOME=/usr/lib/jvm/java-6-sun" | sudo -E tee -a ~/.profile'

# execute 'sudo bash -c "ulimit -n 32768"'
# execute 'echo "* soft nofile 32768" | sudo tee -a /etc/security/limits.conf'
# execute 'echo "* hard nofile 32768" | sudo tee -a /etc/security/limits.conf'
# execute 'sync'
# execute 'echo 3 > /proc/sys/vm/drop_caches'