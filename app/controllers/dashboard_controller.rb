require 'helper'
class DashboardController < ApplicationController
  include Helper

  # KCSDB starts from here
  def show
    # check if Chef Server is set up or not
    @state = get_state
    @status = ""
    
    if @state['chef_server_state'] == 'not_setup'
      @status << ":::::: Chef Server is <strong>not setup</strong> ::::::\n\n"
      @status << "This is the first time you use KCSDB, please click on tab <strong>About</strong> to get more information\n\n"
      @status << "After reading, do as follows\n"
      @status << "<em>First</em>, click on tab <strong>Configuration</strong>, input your <strong>AWS Credentials</strong>\n\n"
      @status << "<em>Second</em>, click on tab <strong>Infrastructure</strong>, create a <strong>fresh Chef Server</strong>"
    else
      @status += ":::::: Chef Server is now <strong>ready</strong> ::::::\n\n"
      @status += "Click on tab <strong>Infrastructure</strong>, then <strong>Check | Start | Stop | Go to Chef Server</strong>\n\n"
      @status += "Please ensure that all <strong>AWS credentials</strong> are correct!"
    end
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
    state['chef_client_identity_file'] = 'dummy'  
    state['chef_client_template_file'] = 'dummy'
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
    logger.debug "::: Deleting monitoring folder in KCSDB Server... [OK]"
    
    logger.debug "::: Reset done [OK]"
    redirect_to "/"
  end
end
