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
    state['chef_client_template_file'] = "#{Rails.root}/chef-repo/bootstrap/ubuntu12.04-new-gems.erb"
    update_state state    
    
    ec2 = create_ec2
    
    logger.debug "====================="
    logger.debug "Checking the key pair"
    logger.debug "====================="

    key_pair_name = params[:key_pair_and_group]
    security_group_name = params[:key_pair_and_group]

    private_key_path = File.expand_path "#{Rails.root}/chef-repo/.chef/pem/#{key_pair_name}.pem"    
    
    # the public key in EC2 with given name and the private key in KCSD Server have to exist
    if  (File.exist? private_key_path) && (! ec2.key_pairs.get(key_pair_name).nil?)
      logger.debug "::: The private key #{key_pair_name}.pem in KCSDB Web Server: [OK]"
      logger.debug "::: The public key #{key_pair_name} in AWS EC2: [OK]"
    else
      logger.debug "::: Something wrong with the key pair..."
      logger.debug "::: That means, at least one of two following problems happens:"
      logger.debug "::: 1. The private key does NOT exist in KCSDB Web Server"
      logger.debug "::: 2. The public key does NOT exist in AWS EC2"
      if File.exist? private_key_path
        logger.debug "::: Deleting the private key in KCSDB Server..."
        File.delete private_key_path
        logger.debug "::: Deleting the private key in KCSDB Server... [OK]"
      end
      if ! ec2.key_pairs.get(key_pair_name).nil?
        logger.debug "::: Deleting the public key in AWS EC2..."
        ec2.delete_key_pair key_pair_name
        logger.debug "::: Deleting the public key in AWS EC2... [OK]"
      end

      logger.debug "::: Creating a new key pair..."
      key_pair = ec2.create_key_pair key_pair_name
      logger.debug "::: Creating a new key pair... [OK]"

      logger.debug "::: Saving #{key_pair_name}.pem..."
      private_key = key_pair.body['keyMaterial']
      File.open(private_key_path,'w') {|file| file << private_key}
      logger.debug "::: Saving #{key_pair_name}.pem... [OK]"

      # only user can read/write
      logger.debug "::: Setting mode 600 for the #{key_pair_name}.pem..."
      File.chmod(0600,private_key_path)
      logger.debug "::: Setting mode 600 for the #{key_pair_name}.pem... [OK]"
      
      logger.debug "::: The private key #{key_pair_name}.pem in KCSDB Web Server: [OK]"
      logger.debug "::: The public key #{key_pair_name} in AWS EC2: [OK]"
    end

    logger.debug "==========================="
    logger.debug "Checking the security group"
    logger.debug "==========================="    
    
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
