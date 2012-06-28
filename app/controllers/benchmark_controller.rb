require 'helper'
class BenchmarkController < ApplicationController
  include Helper
  
  # automatically setup YCSB cluster
  def setup
    @status = ""
    ycsb_type = params[:ycsb_type]
    ycsb_client_number = params[:ycsb_client_number]
    logger.debug "::: YCSB Type: #{ycsb_type} is selected..."
    logger.debug "::: YCSB Client Number: #{ycsb_client_number} is selected..."
    
    logger.debug "::: Lauching #{ycsb_client_number} machines..."
    
    
    
    

    
    @status << ycsb_type << " " << ycsb_client_number
  end
  
  
  private
  def deploy_a_ycsb_client
    state = get_state
        
    
    # chef_client_ami: ami-82fa58eb
# chef_client_ssh_user: ubuntu
# chef_client_bootstrap_version: 10.12.0
# chef_client_role: init
# chef_client_aws_ssh_key_id: KCSDB
# chef_client_identity_file: /home/lha/Dev/git/kcsd/chef-repo/.chef/pem/KCSDB.pem
# chef_client_template_file: /home/lha/Dev/git/kcsd/chef-repo/bootstrap/ubuntu12.04-gems.erb

    
    
    logger.debug "::: Deploying an YCSB Client..."
    
    
  end
end
