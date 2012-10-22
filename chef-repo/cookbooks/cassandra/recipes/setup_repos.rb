#include_recipe "apt"

# Find package codenames
#node[:internal][:codename] = node['lsb']['codename']

# Adds the Cassandra repo:
# deb http://www.apache.org/dist/cassandra/debian <07x|08x|10x|11x> main
=begin
if node[:setup][:deployment] == "07x" or node[:setup][:deployment] == "08x" or node[:setup][:deployment] == "10x" or node[:setup][:deployment] == "11x"
  apt_repository "cassandra-repo" do
    uri "http://www.apache.org/dist/cassandra/debian"
    components [node[:setup][:deployment], "main"]
    keyserver "pgp.mit.edu"
    # key "F758CE318D77295D"
    key "4BD736A82B5C1B00" # for Cassandra 1.1.5
    action :add
  end
end

if node[:setup][:deployment] == "07x" or node[:setup][:deployment] == "08x" or node[:setup][:deployment] == "10x" or node[:setup][:deployment] == "11x"
  apt_repository "cassandra-repo" do
    uri "http://www.apache.org/dist/cassandra/debian"
    components [node[:setup][:deployment], "main"]
    keyserver "pgp.mit.edu"
    key "2B5C1B00"
    action :add
  end
end
=end

# Install DataStax Cassandra
execute 'sudo apt-get update -qq'
execute 'echo "deb http://debian.datastax.com/community stable main" | sudo -E tee -a /etc/apt/sources.list'
execute 'curl -L http://debian.datastax.com/debian/repo_key | sudo apt-key add -'
execute 'sudo apt-get update -qq'
execute 'sudo apt-get install dsc1.1 -qq'
execute 'sudo service cassandra stop'

