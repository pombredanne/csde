require 'rubygems'
require 'jmx4r'
require 'java'
require 'fog'

profile_id = "dummy"

host = "dummy"
port = "7199"

aws_access_key_id = "dummy"
aws_secret_access_key = "dummy"

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

s3 = Fog::Storage.new(
  provider: 'AWS',
  aws_access_key_id: aws_access_key_id,
  aws_secret_access_key: aws_secret_access_key,
  region: 'us-east-1'
)

# check if a bucket called 'kcsdb-results' already exists
dirs = s3.directories
check = false
dirs.each {|dir| if dir.key == "kcsdb-results" then check = true end}
      
# if this bucket does not exist than create a new one
kcsdb_results = nil
if ! check
  puts "Bucket 'kcsdb-results' does NOT exist, create a new one..."
  kcsdb_results = s3.directories.create(
    :key => "kcsdb-results",
    :public => true
  )
else
  puts "Bucket 'kcsdb-results' EXIST, get the bucket..."
  kcsdb_results = s3.directories.get 'kcsdb-results'
end    

# find the right index for the result
index = 0
check = ""
until check.nil? do
  check = kcsdb_results.files.get "#{profile_id}-results-#{index}.txt"
  index += 1
end

puts "Uploading result: #{profile_id}-results-#{index - 1}.txt to S3..."
file = kcsdb_results.files.create(
  :key    => "#{profile_id}-results-#{index - 1}.txt",
  :body   => str,
  :public => true
)   