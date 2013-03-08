if node[:cassandra][:os] == 'ubuntu'
  # set up JAVA_HOME
  execute 'echo "export JAVA_HOME=/usr/lib/jvm/java-6-sun" | sudo -E tee -a ~/.bashrc'
  execute 'echo "export JAVA_HOME=/usr/lib/jvm/java-6-sun" | sudo -E tee -a ~/.profile'
  
  # use MX4J
  #execute 'wget https://s3.amazonaws.com/kcsdb-init/mx4j-tools.jar -O /home/ubuntu/mx4j-tools.jar'
  #execute 'sudo cp /home/ubuntu/mx4j-tools.jar /usr/share/cassandra/lib'
else
  execute 'echo "export JAVA_HOME=/usr/java/jdk1.6.0_41" | sudo -E tee -a ~/.bashrc'
  execute 'echo "export JAVA_HOME=/usr/java/jdk1.6.0_41" | sudo -E tee -a ~/.bash_profile'
end



