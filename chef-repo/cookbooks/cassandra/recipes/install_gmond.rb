# install Gmond
execute "apt-get install ganglia-monitor -qq"

# configure Gmond
ruby_block "configure_gmond" do
  block do
    file_name = "/etc/ganglia/gmond.conf"
    gmond_conf = File.read file_name
    gmond_conf.gsub!(/name = "unspecified"/, "name = \"cassandra\"") # name of the cluster -> cassandra
    gmond_conf.gsub!(/location = "unspecified"/, "location = \"#{node[:cassandra][:gmond_collector]}\"") # the collector of the cluster
    gmond_conf.gsub!(/mcast_join.*/, "#mcast_join") # deactivate this option cause Ubuntu does NOT support
    gmond_conf.gsub!(/bind.*/,"#bind") # deactivate this option cause Ubuntu does NOT support
  end
end

# restart Gmond
execute "/etc/init.d/ganglia-monitor restart"
