require 'helper'
class BenchmarkController < ApplicationController
  include Helper
  
  def run
    @status = ""
    
    benchmark_profile_url = params[:benchmark_profile_url]
    
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
        @status << "Profile is NOT conform. Please see the sample to write a good benchmark profile"
      end
    end
    
    logger.debug "::: Services:"
    puts service_array
    
    logger.debug "::: Profiles:"
    puts profile_array
    
    logger.debug "========================================="
    logger.debug "::: Parsing the benchmark profile... [OK]"
    logger.debug "========================================="

    # NOW, run each profile
    profile_counter = 1
    profile_array.each do |profile|
      logger.debug "::: Running profile #{profile_counter}..."
      
      # each profile uses a dedicated provider
      # aws | rackspace | zimory
      provider = profile['provider']
      logger.debug "Provider: #{provider}"
      
      region_array = []
      region_counter = 1
      region_found = true
      
      # seek regions
      until ! region_found
        if profile.key? "region#{region_counter}" 
          region_array << profile["region#{region_counter}"]
          region_counter = region_counter + 1
        else
          region_found = false
        end
      end
      
      logger.debug "Regions:"
      puts region_array
      
      check_multiple_region = false
      if region_array.size > 1
        check_multiple_region = true
        logger.debug "Deploying database cluster in multiple regions..."        
      else
        logger.debug "Deploying database cluster in single region..."
      end
      
      
      
      
      
      
      profile_counter = profile_counter + 1
    end
        
  end
  
  private
  def template_parse template_string
    
  end
  
  private
  def service service_name, attribute_array
    if service_name == 'cassandra'
      service_cassandra attribute_array
    elsif service_name == 'ycsb'
      service_ycsb attribute_array
    elsif service_name == 'gmond'
      service_gmond attribute_array
    end  
  end
  
  private
  def service_cassandra attribute_array
    logger.debug "::: Service: Cassandra is being deployed..." 
  end
  
  private
  def service_ycsb attribute_array
    logger.debug "::: Service: YCSB is being deployed..."
  end
  
  private
  def service_gmond attribute_array
    logger.debug "::: Service: Gmond is being deployed..."
  end
  
  private
  def template_parse
    
  end
  
end