require 'helper'
class ConfigurationController < ApplicationController
  include Helper
  
  # update state.yml
  def edit_ibm
    state = get_state
    state['ibm_username'] = params[:ibm_username]
    state['ibm_password'] = params[:ibm_password]
    state['ibm_private_key'] = params[:ibm_private_key]
    state['ibm_chef_client_ssh_key_id'] = params[:ibm_private_key]
    state['notification_email'] = params[:notification_email]
    state['chef_client_template_file'] = "dummy"
    update_state state    

    # TODO
    # support more regions
    supported_regions = []
    supported_regions << "EHN" # Ehningen, Germany
    # supported_regions << "RTP" # Raleigh, U.S.A
    # supported_regions << "us-co-dc1" # Boulder1, U.S.A
    # supported_regions << "ca-on-dc1" # Markham, Canada
    # supported_regions << "ap-jp-dc1" # Makuhari, Japan
    # supported_regions << "ap-sg-dc1" # Singapore, Singapore
    logger.debug "--------------------------"
    logger.debug "::: IBM supported regions:"
    logger.debug "--------------------------"
    puts supported_regions
    
    key_pair_name = params[:ibm_private_key]

    logger.debug "-----------------------------------------"
    logger.debug "::: Creating a key pair in each region..."
    logger.debug "-----------------------------------------"
    
    supported_regions.each do |region|
      logger.debug "----------------------------------------"
      logger.debug "Checking IBM SCE in region: #{region}..."
      logger.debug "----------------------------------------"
      
      sce = create_fog_object 'ibm', region, 'compute'
      
      logger.debug "::: Checking the key pair"
  
      private_key_path = File.expand_path "#{Rails.root}/chef-repo/.chef/pem/#{key_pair_name}-#{region}.pem"    
      
      if File.exist? private_key_path
        logger.debug "--- Deleting the OLD private key in CSDE Server..."
        File.delete private_key_path
        logger.debug "Deleting the OLD private key in CSDE Server... [OK]"
      end
      if ! sce.keys.get(key_pair_name).nil?
        logger.debug "--- Deleting the OLD public key in IBM SCE..."
        sce.delete_key key_pair_name
        logger.debug "Deleting the OLD public key in IBM SCE... [OK]"
      end
      
      logger.debug "--- Creating a NEW key pair..."
      key_pair = sce.create_key key_pair_name
      logger.debug "Creating a NEW key pair... [OK]"
  
      logger.debug "--- Saving #{key_pair_name}-#{region}.pem..."
      private_key = key_pair.body['keyMaterial']
      File.open(private_key_path,'w') {|file| file << private_key}
      logger.debug "Saving #{key_pair_name}-#{region}.pem... [OK]"
  
      # only user can read/write
      logger.debug "--- Setting mode 600 for the #{key_pair_name}-#{region}.pem..."
      File.chmod(0600,private_key_path)
      logger.debug "Setting mode 600 for the #{key_pair_name}-#{region}.pem... [OK]"
        
      logger.debug "--- The PRIVATE key #{key_pair_name}-#{region}.pem in CSDE Web Server: [OK]"
      logger.debug "--- The PUBLIC key #{key_pair_name} in IBM SCE: [OK]"
    end
  end
  
  # update state.yml
  def edit_aws
    state = get_state
    state['aws_access_key_id'] = params[:aws_access_key_id]
    state['aws_secret_access_key'] = params[:aws_secret_access_key]
    state['aws_key_pair_name'] = params[:key_pair_and_group]
    state['aws_security_group_name'] = params[:key_pair_and_group]
    state['aws_chef_client_ssh_key_id'] = params[:key_pair_and_group]
    state['notification_email'] = params[:notification_email]
    state['chef_client_template_file'] = "#{Rails.root}/chef-repo/bootstrap/ubuntu12.04-new-light-gems.erb"
    update_state state    

    # TODO
    # support more regions
    supported_regions = []
    supported_regions << "us-east-1" # US EAST Virginira
    supported_regions << "us-west-1" # US WEST N. California
    supported_regions << "us-west-2" # US WEST Oregon
    supported_regions << "eu-west-1" # EU WEST Ireland
    logger.debug "--------------------------"
    logger.debug "::: AWS supported regions:"
    logger.debug "--------------------------"
    puts supported_regions

    key_pair_name = params[:key_pair_and_group]
    security_group_name = params[:key_pair_and_group]

    logger.debug "--------------------------------------------------------------"
    logger.debug "::: Creating a key pair and a security group in each region..."
    logger.debug "--------------------------------------------------------------"
    
    supported_regions.each do |region|
      logger.debug "------------------------------------"
      logger.debug "Checking AWS in region: #{region}..."
      logger.debug "------------------------------------"
      
      ec2 = create_fog_object 'aws', region, 'compute'
      
      logger.debug "::: Checking the key pair"
  
      private_key_path = File.expand_path "#{Rails.root}/chef-repo/.chef/pem/#{key_pair_name}-#{region}.pem"    
      
      if File.exist? private_key_path
        logger.debug "--- Deleting the OLD private key in CSDE Server..."
        File.delete private_key_path
        logger.debug "Deleting the OLD private key in CSDE Server... [OK]"
      end
      if ! ec2.key_pairs.get(key_pair_name).nil?
        logger.debug "--- Deleting the OLD public key in AWS EC2..."
        ec2.delete_key_pair key_pair_name
        logger.debug "Deleting the OLD public key in AWS EC2... [OK]"
      end
      
      logger.debug "--- Creating a NEW key pair..."
      key_pair = ec2.create_key_pair key_pair_name
      logger.debug "Creating a NEW key pair... [OK]"
  
      logger.debug "--- Saving #{key_pair_name}-#{region}.pem..."
      private_key = key_pair.body['keyMaterial']
      File.open(private_key_path,'w') {|file| file << private_key}
      logger.debug "Saving #{key_pair_name}-#{region}.pem... [OK]"
  
      # only user can read/write
      logger.debug "--- Setting mode 600 for the #{key_pair_name}-#{region}.pem..."
      File.chmod(0600,private_key_path)
      logger.debug "Setting mode 600 for the #{key_pair_name}-#{region}.pem... [OK]"
        
      logger.debug "--- The PRIVATE key #{key_pair_name}-#{region}.pem in CSDE Web Server: [OK]"
      logger.debug "--- The PUBLIC key #{key_pair_name} in AWS EC2: [OK]"
  
      logger.debug "::: Checking the security group"
      
      # check if the security group with the given name exists in AWS EC2
      if ! ec2.security_groups.get(security_group_name).nil?
        logger.debug "--- The security group #{security_group_name} in AWS EC2: [OK]"
      else
        logger.debug "--- Creating a new security group #{security_group_name} in AWS EC2..."
        ec2.create_security_group(security_group_name,'Security Group for CSDE')
        
        # TODO
        # too much open security group
        group = ec2.security_groups.get security_group_name
        group.authorize_port_range(0..65535,:ip_protocol => 'tcp') # all TCP connections from all sources
        group.authorize_port_range(0..65535,:ip_protocol => 'udp') # all UDP connections from all sources
        logger.debug "Creating a new security group #{security_group_name} in AWS EC2... [OK]"
      end  
    end
  end
end
