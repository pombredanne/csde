ruby_block "configure_cluster" do
  block do
    File.open(node[:cassandra][:configure_file],"w") do |file|
      file << "create keyspace #{node[:cassandra][:keyspace]} with strategy_options = {replication_factor:#{node[:cassandra][:replication_factor]}} and placement_strategy = 'org.apache.cassandra.locator.SimpleStrategy';"
      file << "\n"
      file << "use #{node[:cassandra][:keyspace]};"
      file << "\n"
      file << "create column family #{node[:cassandra][:column_family]} with comparator='AsciiType';"
    end
      
    system "cassandra-cli -h localhost -p 9160 -f #{node[:cassandra][:configure_file]}"
  end
end