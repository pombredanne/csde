include_recipe "apt"

# Find package codenames
node[:internal][:codename] = node['lsb']['codename']

# Adds the Cassandra repo:
# deb http://www.apache.org/dist/cassandra/debian <07x|08x|10x|11x> main
if node[:setup][:deployment] == "07x" or node[:setup][:deployment] == "08x" or node[:setup][:deployment] == "10x" or node[:setup][:deployment] == "11x"
  apt_repository "cassandra-repo" do
    uri "http://www.apache.org/dist/cassandra/debian"
    components [node[:setup][:deployment], "main"]
    keyserver "pgp.mit.edu"
    key "F758CE318D77295D"
    action :add
  end
end
