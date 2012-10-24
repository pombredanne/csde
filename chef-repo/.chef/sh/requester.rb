require 'rubygems'
require 'jmx4r'
require 'java'
require 'fog'

host = "54.242.21.155"
port = "7199"

aws_access_key_id = "dummy"
aws_secret_access_key = "dummy"

profile_id = "dummy"

str = ""
str << "----------------------------------------------------------\n"
str << "Establishing connection to host #{host} on port #{port}...\n"
str << "----------------------------------------------------------\n"
JMX::MBean.establish_connection :host => host, :port => port

str << "----------------------------\n"
str << "Requesting caching values...\n"
str << "----------------------------\n"
cache = JMX::MBean.find_by_name "org.apache.cassandra.db:type=Caches"

str << "Key Cache Hits: #{cache.key_cache_hits}\n"
str << "Row Cache Hits: #{cache.row_cache_hits}\n"
str << "Key Cache Request: #{cache.key_cache_requests}\n"
str << "Row Cache Request: #{cache.row_cache_requests}\n"
str << "Key Cache Recent Hit Rate: #{cache.key_cache_recent_hit_rate}\n"
str << "Row Cache Recent Hit Rate: #{cache.row_cache_recent_hit_rate}\n"
str << "Key Cache Save Period In Seconds: #{cache.key_cache_save_period_in_seconds}\n"
str << "Row Cache Save Period In Seconds: #{cache.row_cache_save_period_in_seconds}\n"
str << "Key Cache Capacity in MB: #{cache.key_cache_capacity_in_mb}\n"
str << "Row Cache Capacity in MB: #{cache.row_cache_capacity_in_mb}\n"
str << "Key Cache Size: #{cache.key_cache_size}\n"
str << "Row Cache Size: #{cache.row_cache_size}\n"

File.open("/home/ubuntu/erg.txt",'w'){|f| f.write str}

s3 = Fog::Storage.new(
  provider: 'AWS',
  aws_access_key_id: aws_access_key_id,
  aws_secret_access_key: aws_secret_access_key,
  region: 'us-east-1'
)