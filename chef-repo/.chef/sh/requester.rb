require 'rubygems'
require 'java'
require 'jmx4r'

host = ARGV[0]
port = ARGV[1]

puts "----------------------------------------------------------"
puts "Establishing connection to host #{host} on port #{port}..."
puts "----------------------------------------------------------"
JMX::MBean.establish_connection :host => host, :port => port

puts "----------------------------"
puts "Requesting caching values..."
puts "----------------------------"
cache = JMX::MBean.find_by_name "org.apache.cassandra.db:type=Caches"

puts "Key Cache Hits: #{cache.key_cache_hits}"
puts "Row Cache Hits: #{cache.row_cache_hits}"
puts "Key Cache Request: #{cache.key_cache_requests}"
puts "Row Cache Request: #{cache.row_cache_requests}"
puts "Key Cache Recent Hit Rate: #{cache.key_cache_recent_hit_rate}"
puts "Row Cache Recent Hit Rate: #{cache.row_cache_recent_hit_rate}"
puts "Key Cache Save Period In Seconds: #{cache.key_cache_save_period_in_seconds}"
puts "Row Cache Save Period In Seconds: #{cache.row_cache_save_period_in_seconds}"
puts "Key Cache Capacity in MB: #{cache.key_cache_capacity_in_mb}"
puts "Row Cache Capacity in MB: #{cache.row_cache_capacity_in_mb}"
puts "Key Cache Size: #{cache.key_cache_size}"
puts "Row Cache Size: #{cache.row_cache_size}"