require 'helper'
class ConfigurationController < ApplicationController
  include Helper
  
  # update state.yml
  def edit_aws
    state = get_state
    state['aws_access_key_id'] = params[:aws_access_key_id]
    state['aws_secret_access_key'] = params[:aws_secret_access_key]
    state['key_pair_name'] = params[:key_pair_and_group]
    state['security_group_name'] = params[:key_pair_and_group]
    state['chef_client_aws_ssh_key_id'] = params[:key_pair_and_group]
    state['chef_client_identity_file'] = "#{Rails.root}/chef-repo/.chef/pem/#{params[:key_pair_and_group]}.pem"
    state['chef_client_template_file'] = "#{Rails.root}/chef-repo/bootstrap/ubuntu12.04-new-light-gems.erb"
    update_state state    

    supported_regions = []
    supported_regions << "us-east-1"
    supported_regions << "us-west-1"

    key_pair_name = params[:key_pair_and_group]
    security_group_name = params[:key_pair_and_group]

    supported_regions.each do |region|
      logger.debug "------------------------------------"
      logger.debug "Checking AWS in region: #{region}..."
      logger.debug "------------------------------------"
      
      ec2 = create_fog_object 'aws', region
      
      logger.debug "::: Checking the key pair"
  
      private_key_path = File.expand_path "#{Rails.root}/chef-repo/.chef/pem/#{key_pair_name}-#{region}.pem"    
      
      if File.exist? private_key_path
        logger.debug "::: Deleting the OLD private key in KCSDB Server..."
        File.delete private_key_path
        logger.debug "::: Deleting the OLD private key in KCSDB Server... [OK]"
      end
      if ! ec2.key_pairs.get(key_pair_name).nil?
        logger.debug "::: Deleting the OLD public key in AWS EC2..."
        ec2.delete_key_pair key_pair_name
        logger.debug "::: Deleting the OLD public key in AWS EC2... [OK]"
      end
      
      logger.debug "::: Creating a NEW key pair..."
      key_pair = ec2.create_key_pair key_pair_name
      logger.debug "::: Creating a NEW key pair... [OK]"
  
      logger.debug "::: Saving #{key_pair_name}-#{region}.pem..."
      private_key = key_pair.body['keyMaterial']
      File.open(private_key_path,'w') {|file| file << private_key}
      logger.debug "::: Saving #{key_pair_name}-#{region}.pem... [OK]"
  
        # only user can read/write
      logger.debug "::: Setting mode 600 for the #{key_pair_name}-#{region}.pem..."
      File.chmod(0600,private_key_path)
      logger.debug "::: Setting mode 600 for the #{key_pair_name}-#{region}.pem... [OK]"
        
      logger.debug "::: The PRIVATE key #{key_pair_name}-#{region}.pem in KCSDB Web Server: [OK]"
      logger.debug "::: The PUBLIC key #{key_pair_name} in AWS EC2: [OK]"
  
      logger.debug "::: Checking the security group"
      
      # check if the security group with the given name exists in AWS EC2
      if ! ec2.security_groups.get(security_group_name).nil?
        logger.debug "::: The security group #{security_group_name} in AWS EC2: [OK]"
      else
        logger.debug "::: Creating a new security group #{security_group_name} in AWS EC2..."
        ec2.create_security_group(security_group_name,'Security Group for KCSD')
        
        # TODO
        # too much open security group
        # logger.debug "::: Opening ALL ports from ALL sources for TCP and UDP..."
        group = ec2.security_groups.get security_group_name
        group.authorize_port_range(0..65535)
        logger.debug "::: Creating a new security group #{security_group_name} in AWS EC2... [OK]"
        
        logger.debug "::: The security group #{security_group_name} in AWS EC2: [OK]"
      end  
    end
  end
end
