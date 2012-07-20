require 'helper'
class BenchmarkController < ApplicationController
  include Helper
  
  def run
    @status = ""
    
    benchmark_profile_url = params[:benchmark_profile_url]
      
    @status << benchmark_profile_url    
  end
  
  # parse the profile file to get configuration parameters
  private
  def profile_parse
    
  end
end
