ruby_block "configure_cluster" do
  block do
    File.open(node[:cassandra][:configure_file],"w") do |file|
      file << "create keyspace #{node[:cassandra][:keyspace]} with strategy_options = {#{node[:cassandra][:replication_factor]}} and placement_strategy = '#{node[:cassandra][:placement_strategy]}';"
      file << "\n"
      file << "use #{node[:cassandra][:keyspace]};"
      file << "\n"
      file << "create column family #{node[:cassandra][:column_family]} with comparator='AsciiType';"
      file << "\n"
      
      # NO cache
      if (node[:cassandra][:key_cache_size_in_mb] == "0") && (node[:cassandra][:row_cache_size_in_mb] == "0")
        file << "update column family #{node[:cassandra][:column_family]} with caching=none;"
      end
      
      # only KEY cache
      if (! node[:cassandra][:key_cache_size_in_mb] == "0") && (node[:cassandra][:row_cache_size_in_mb] == "0")
        file << "update column family #{node[:cassandra][:column_family]} with caching=keys_only;"
      end
      
      # only ROW cache
      if (node[:cassandra][:key_cache_size_in_mb] == "0") && (! node[:cassandra][:row_cache_size_in_mb] == "0")
        file << "update column family #{node[:cassandra][:column_family]} with caching=rows_only;"
      end
      
      # ALL cache
      if (! node[:cassandra][:key_cache_size_in_mb] == "0") && (! node[:cassandra][:row_cache_size_in_mb] == "0")
        file << "update column family #{node[:cassandra][:column_family]} with caching=all;"
      end
    end
      
    system "cassandra-cli -h localhost -p 9160 -f #{node[:cassandra][:configure_file]}"
  end
end