require 'helper'
class BenchmarkController < ApplicationController
  include Helper
  
  def run
    @status = ""
    
    benchmark_profile_url = params[:benchmark_profile_url]
    @status << benchmark_profile_url
    
    logger.debug "::: Parsing the benchmark profile..."
    configuration_array = profile_parse benchmark_profile_url
        
  end
  
  # parse the profile file to get configuration parameters
  private
  def profile_parse benchmark_profile_url
    # contain all configuration parameters
    configuration_array = []
    
    logger.debug "::: Getting the benchmark profile from the given source..."
    benchmark_profile_path = "#{Rails.root}/chef-repo/.chef/tmp/benchmark_profiles.yaml"
    system "curl -L #{benchmark_profile_url} -o #{benchmark_profile_path}"
    logger.debug "::: Getting the benchmark profile from the given source... [OK]"
    
    logger.debug "===================================="
    logger.debug "::: Parsing the benchmark profile..."
    logger.debug "===================================="
    benchmark_profiles = Psych.load(File.open benchmark_profile_path)
    
    # contain all keys of benchmark profiles
    # the keys are splitted in 2 groups
    # service key: service1, service2, etc...
    # profile key: profile1, profile2, etc...
    key_array = benchmark_profiles.keys
    logger.debug "::: Keys:"
    puts key_array
    
    # contain service1, service2, etc..
    # each service is a hash map, e.g. name => cassandra, attribute => { replication_factor => 3, partitioner => RandomPartitioner }
    service_array = []
    
    # contain profile1, profile2
    # each profile is a hash map, e.g. provider => aws, region1 => { name => us-east-1, machine_type => small, template => 3 service1+service2}
    profile_array = []
    
    key_array.each do |key|
      if key.to_s.include? "service"
        service_array << benchmark_profiles[key]
      elsif key.to_s.include? "profile"
        profile_array << benchmark_profiles[key]
      else
        logger.debug "::: Profile is NOT conform. Please see the sample to write a good benchmark profile"
        exit 0
      end
    end
    
    logger.debug "::: Services:"
    puts service_array
    
    logger.debug "::: Profiles:"
    puts profile_array
    
    logger.debug "========================================="
    logger.debug "::: Parsing the benchmark profile... [OK]"
    logger.debug "========================================="
    
    configuration_array
  end
end
