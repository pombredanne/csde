require 'rubygems'
require 'java'
require 'jmx4r'

host = "54.242.21.155"
port = "7199"

str = ""
str << "----------------------------------------------------------"
str << "Establishing connection to host #{host} on port #{port}..."
str << "----------------------------------------------------------"
JMX::MBean.establish_connection :host => host, :port => port

str << "----------------------------"
str << "Requesting caching values..."
str << "----------------------------"
cache = JMX::MBean.find_by_name "org.apache.cassandra.db:type=Caches"

str << "Key Cache Hits: #{cache.key_cache_hits}"
str << "Row Cache Hits: #{cache.row_cache_hits}"
str << "Key Cache Request: #{cache.key_cache_requests}"
str << "Row Cache Request: #{cache.row_cache_requests}"
str << "Key Cache Recent Hit Rate: #{cache.key_cache_recent_hit_rate}"
str << "Row Cache Recent Hit Rate: #{cache.row_cache_recent_hit_rate}"
str << "Key Cache Save Period In Seconds: #{cache.key_cache_save_period_in_seconds}"
str << "Row Cache Save Period In Seconds: #{cache.row_cache_save_period_in_seconds}"
str << "Key Cache Capacity in MB: #{cache.key_cache_capacity_in_mb}"
str << "Row Cache Capacity in MB: #{cache.row_cache_capacity_in_mb}"
str << "Key Cache Size: #{cache.key_cache_size}"
str << "Row Cache Size: #{cache.row_cache_size}"

File.open("/home/ubuntu/erg.txt",'w'){|f| f.write str}