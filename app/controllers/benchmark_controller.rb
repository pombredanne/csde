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
    
    
    configuration_array
  end
end
