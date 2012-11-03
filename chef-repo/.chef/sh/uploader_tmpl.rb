require 'rubygems'
require 'fog'

profile_id = "dummy"

aws_access_key_id = "dummy"
aws_secret_access_key = "dummy"

puts "-----------------------------------------------------"
puts "Invoking Uploader in order to upload results to S3..."
puts "-----------------------------------------------------"

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
  :body   => File.open("/home/ubuntu/results.txt"),
  :public => true
)   