# set up JAVA_HOME
execute 'echo "export JAVA_HOME=/usr/lib/jvm/java-6-sun" | sudo -E tee -a ~/.bashrc'
execute 'echo "export JAVA_HOME=/usr/lib/jvm/java-6-sun" | sudo -E tee -a ~/.profile'


# use MX4J
execute 'wget https://s3.amazonaws.com/kcsdb-init/mx4j-tools.jar'
execute 'sudo cp /home/ubuntu/mx4j-tools.jar /usr/share/cassandra/lib'