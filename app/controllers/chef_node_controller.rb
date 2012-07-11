require 'helper'
class ChefNodeController < ApplicationController
  include Helper
  
  # 1. provision new machines in EC2
  # 2. knife bootstrap these machines
  def create
    number = params[:number_create].to_i
    logger.debug "::: Creating #{number} machine(s)..."

    flavor = ""
    if params[:flavor_create] == "small_create"
      flavor = "m1.small"
    elsif params[:number_create] == "medium_create"
      flavor = "m1.medium"
    else
      flavor = "m1.large"  
    end
    logger.debug "::: Flavor: #{flavor} selected..."
    
    token = '{"lha" : "0000"}'
    puts token
    
    tags = 'tokendummy=0000000'
    
    threads = []
    number.times do
      thread = Thread.new { system(knife_ec2_bootstrap flavor,tags)}
      threads << thread
    end
    
    # parallel bootstrap
    threads.each {|t| t.join}
    logger.debug "::: Knife Bootstrapping END [OK]"
  end
  
  # knife ec2 server create
  # flavor: m1.small | m1.medium | m1.large
  # token: which token position should the node have, the token is passed by KCSDB Server
  private
  def knife_ec2_bootstrap flavor,tags
    
    $stdout.sync = true
    
    knife_ec2_bootstrap_string = ""
    state = get_state
    
    logger.debug "::: Creating a new machine..."
    aws_access_key_id = state['aws_access_key_id']
    aws_secret_access_key = state['aws_secret_access_key']
    region = state['region']    
    security_group_name = state['security_group_name']
    chef_client_ami = state['chef_client_ami']
    chef_client_identity_file = state['chef_client_identity_file']
    chef_client_flavor = flavor
    chef_client_ssh_user = state['chef_client_ssh_user']
    chef_client_bootstrap_version = state['chef_client_bootstrap_version']
    chef_client_role = state['chef_client_role']
    chef_client_aws_ssh_key_id = state['chef_client_aws_ssh_key_id']
    chef_client_template_file = state['chef_client_template_file']
    chef_client_token_position = tags
   
    knife_ec2_bootstrap_string << "rvmsudo knife ec2 server create "
    knife_ec2_bootstrap_string << "--config #{Rails.root}/chef-repo/.chef/conf/knife.rb "
    knife_ec2_bootstrap_string << "--aws-access-key-id #{aws_access_key_id} "
    knife_ec2_bootstrap_string << "--aws-secret-access-key #{aws_secret_access_key} "
    knife_ec2_bootstrap_string << "--region #{region} "
    knife_ec2_bootstrap_string << "--groups #{security_group_name} "
    knife_ec2_bootstrap_string << "--image #{chef_client_ami} "
    knife_ec2_bootstrap_string << "--identity-file #{chef_client_identity_file} "
    knife_ec2_bootstrap_string << "--flavor #{chef_client_flavor} "
    knife_ec2_bootstrap_string << "--ssh-user #{chef_client_ssh_user} "
    knife_ec2_bootstrap_string << "--bootstrap-version #{chef_client_bootstrap_version} "
    knife_ec2_bootstrap_string << "--ssh-key #{chef_client_aws_ssh_key_id} "
    knife_ec2_bootstrap_string << "--template-file #{chef_client_template_file} "
    knife_ec2_bootstrap_string << "--run-list \'role[#{chef_client_role}]\' "
    knife_ec2_bootstrap_string << "--yes "
    knife_ec2_bootstrap_string << "--no-host-key-verify "
    knife_ec2_bootstrap_string << "--tags \'#{chef_client_token_position}\' "
    # knife_ec2_bootstrap_string << "-VV "
    
    logger.debug "::: The knife bootstrap command: #{knife_ec2_bootstrap_string}"
    knife_ec2_bootstrap_string
  end
  
  # count how many machines are available in the infrastructure
  def check
    machine_array = get_machine_array

    # counter
    small = 0
    medium = 0
    large = 0
    
    # counting
    machine_array.each do |server|
      if(server.flavor_id.to_s == "m1.small")
          small += 1
      elsif(server.flavor_id.to_s == "m1.medium")
          medium += 1
      elsif(server.flavor_id.to_s == "m1.large")
          large += 1
      end
    end

    logger.debug "::: Now, we have #{machine_array.size} machine(s) in the infrastructure"
    logger.debug "::: Small: #{small}"
    logger.debug "::: Medium: #{medium}"
    logger.debug "::: Large: #{large}"

    @status = "Now we have <strong>#{machine_array.size}</strong> machine(s) in the infrastructure\n\n"
    @status << "<strong>Small</strong> machines: #{small}\n"
    @status << "<strong>Medium</strong> machines: #{medium}\n"
    @status << "<strong>Large</strong> machines: #{large}\n"
  end

  # show all machines that KCSDB manages
  def show_all
    machine_array = get_machine_array
    @info_array = []
    machine_array.each do |server|
      tmp_array = []
      tmp_array << server.id
      tmp_array << server.public_ip_address
      tmp_array << server.private_ip_address
      tmp_array << server.flavor_id
      tmp_array << server.image_id
      tmp_array << server.state.to_s
      @info_array << tmp_array
    end
    @info_array
  end

  # stop all machines that KCSDB manages
  def stop_all
    machine_array = get_machine_array
    @status = ""
    machine_array.each do |server|
      # can only stop instances that are running
      if server.state.to_s != "running"
        logger.debug "::: Machine: #{server.id} is now in the state: #{server.state.to_s} and can not be stopped"
        @status << "Machine: <strong>#{server.id}</strong> is now in state <strong>#{server.state.to_s}</strong> and can not be stopped\n"
      else
        server.stop
        logger.debug "::: Machine: #{server.id} is now being stopped..."
        @status << "Machine: <strong>#{server.id}</strong> is now being stopped\n"
      end
    end
    @status
  end

  # start some selected machines
  def start
    machine_array = get_machine_array
    state = get_state
    identity_file = state['chef_client_identity_file']
    ssh_user = state['chef_client_ssh_user']

    # get params
    logger.debug "::: Getting parameter from user..."
    number = params[:number_start].to_i
    flavor = ""
    if(params[:flavor_start] == "small_start")
      flavor = "m1.small"
    elsif(params[:flavor_start] == "medium_start")
      flavor = "m1.medium"
    else
      flavor = "m1.large"
    end
    logger.debug "::: Number machines to be started: #{number}"
    logger.debug "::: Machine type: #{flavor}"

    # max is the available machines with a selected type can be invoked
    # for example:
    # 5 small instances, currently 2 are running
    # => max = 3
    max = 0
    logger.debug "::: Calculating the maximal number of machine with type: #{flavor} can be started..."
    machine_array.each do |server|
      if (server.flavor_id.to_s == flavor) && (server.state.to_s != "running")
        max += 1
      end
    end

    # enough machines
    if (number <= max)
      logger.debug "::: Enough machines to start"
      
      # get the machines with the selected flavor
      # and with the state stopped
      tmp_array = []
      machine_array.each do |server|
        if (server.flavor_id.to_s == flavor) && (server.state.to_s == "stopped")
          tmp_array << server
        end
      end

      # multi threaded
      # 1. start a machine
      # 2. wait until sshd ready
      # 3. invoke chef-client
      threads = []
      delta = number - 1
      for i in 0..delta
        thread = Thread.new {
          logger.debug "::: Starting machine: #{tmp_array[i].id}..."
          tmp_array[i].start
          logger.debug "::: Starting machine: #{tmp_array[i].id}... [OK]"
          
          # meta data for each server is automatically updated, cool :)!
          logger.debug "::: Waiting for machine: #{tmp_array[i].id}..."
          tmp_array[i].wait_for { print "."; ready? }
          puts "\n"
          logger.debug "::: Waiting for machine: #{tmp_array[i].id}... [OK]"
          
          print "." until tcp_test_ssh(tmp_array[i].public_ip_address) { sleep 1 }
          
          # invoking chef-client process by every starting to update the meta info in each chef node
          logger.debug "::: Invoking chef-client process..."
          ssh_command = "ssh "
          ssh_command << "-i #{identity_file} "
          ssh_command << "-o 'UserKnownHostsFile /dev/null' -o StrictHostKeyChecking=no "
          ssh_command << "#{ssh_user}@#{tmp_array[i].public_ip_address} "
          ssh_command << "'sudo chef-client'"
          puts ssh_command
          system ssh_command
          logger.debug "::: Invoking chef-client process... [OK]"
        }
        threads << thread
      end
      
      threads.each { |t| t.join }        
      logger.debug "::: END"

      @status = "Start <strong>#{number}</strong> machines with flavor <strong>#{flavor}</strong>\n\n"
      @status << "Click the <strong>back</strong> button below to come back dashboard"
    else
      logger.debug "::: KCSDB has only #{max} machiens with flavor #{flavor} available"
      logger.debug "::: You need #{number} machiens with flavor #{flavor}"
      logger.debug "::: Maybe the some #{flavor} machines are running"
      logger.debug "::: Or you have to create more machines"
      
      @status = "KCSDB has only <strong>#{max}</strong> machines with flavor <strong>#{flavor}</strong> available\n\n"
      @status << "You need <strong>#{number}</strong> machines with flavor <strong>#{flavor}</strong>\n\n"
      @status << "Maybe the some <strong>#{flavor}</strong> machines are running\n\n"
      @status << "Or you have to create <strong>create</strong> more!\n\n"
      @status << "Click the <strong>back</strong> button below to come back dashboard\n\n"
    end
  end
end
