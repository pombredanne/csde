require 'helper'
class DashboardController < ApplicationController
  include Helper

  # KCSDB starts from here
  def show
    update_knife_rb
    
    state = get_state
    
    @aws_access_key_id = state['aws_access_key_id']
    @aws_secret_access_key = state['aws_secret_access_key']
    @key_pair_name = state['key_pair_name']
    @notification_email = state['notification_email']

    @status = "CSDE welcomes you :).\n"
    @status << "Have a great day !!!\n\n"

    @status << "Click on tab <strong>About</strong> to get <strong>more information</strong>\n"
    @status << "Click on tab <strong>Credentials</strong> to input your <strong>AWS Credentials</strong>\n"
    @status << "Click on tab <strong>Configuration</strong> to go to <strong>Chef Server</strong>\n"
    @status << "Click on tab <strong>Monitoring</strong> to go to <strong>Ganglia Server</strong>\n"
    @status << "Click on tab <strong>Benchmark</strong> to define your <strong>benchmark profiles</strong>"
  end
  
  

  # reset KCSDB
  def reset
    # initialize
    machine_array = []
    ec2 = create_ec2
    state = get_state
    key_pair_name = state['key_pair_name']
    elastic_ip = state['chef_server_elastic_ip']
    
    logger.debug "::: Getting all machines including Chef Server..."
    ec2.servers.each do |server|
      # show all the instances that KCSDB manages
      if server.key_name == key_pair_name
        # the machine is not terminated
        if server.state.to_s != 'terminated'
          machine_array << server.id
        end
      end
    end
    logger.debug "::: Getting all machines including Chef Server... [OK]"

    logger.debug "::: Terminating all machines including Chef Server..."
    ec2.terminate_instances machine_array
    logger.debug "::: Terminating all machines including Chef Server... [OK]"

    logger.debug "::: Releasing Chef Server's elastic IP..."
    ec2.release_address elastic_ip
    logger.debug "::: Releasing Chef Server's elastic IP... [OK]"

    state['aws_access_key_id'] = 'dummy'
    state['aws_secret_access_key'] = 'dummy'
    state['key_pair_name'] = 'dummy'
    state['security_group_name'] = 'dummy'
    state['chef_server_state'] = 'not_setup'
    state['chef_server_id'] = 'dummy'
    state['chef_server_elastic_ip'] = 'dummy'
    state['chef_client_aws_ssh_key_id'] = 'dummy'
    state['chef_client_identity_file'] = 'dummy'  
    state['chef_client_template_file'] = 'dummy'
    # state['kcsdb_sudo_password'] = 'dummy'
    update_state state
    
    logger.debug "::: Resetting knife.rb..."
    File.open("#{Rails.root}/chef-repo/.chef/conf/knife.rb",'w') do |file|
      file << "chef_server_url \'dummy\'" << "\n"
      file << "node_name \'dummy\'" << "\n"
      file << "client_key \'dummy\'" << "\n"
      file << "validation_client_name \'dummy\'" << "\n"
      file << "validation_key \'dummy\'" << "\n"
      file << "cookbook_path \'dummy\'"   
    end
    logger.debug "::: Resetting knife.rb... [OK]"
    
    logger.debug "::: Deleting all pem files..."
    system "rm #{Rails.root}/chef-repo/.chef/pem/*pem"
    logger.debug "::: Deleting all pem files... [OK]"

    logger.debug "::: Deleting ssh stuff..."
    if File.exist? "#{ENV['HOME']}/.ssh/config"
      logger.debug "::: Deleting ~/.ssh/config..."
      File.delete "#{ENV['HOME']}/.ssh/config"    
    end
    if File.exist? "#{ENV['HOME']}/.ssh/known_hosts"
      logger.debug "::: Deleting ~/.ssh/known_hosts..."
      File.delete "#{ENV['HOME']}/.ssh/known_hosts"    
    end
    logger.debug "::: Deleting ssh stuff... [OK]"

    logger.debug "::: Deleting monitoring folder in KCSDB Server..."
    if File.exist? "#{ENV['HOME']}/opscenter"
      File.delete "#{ENV['HOME']}/opscenter"
    end
    logger.debug "::: Deleting monitoring folder in KCSDB Server... [OK]"
    
    logger.debug "::: Reset done [OK]"
    redirect_to "/"
  end
end