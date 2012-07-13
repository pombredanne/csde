require 'helper'
class ChefNodeController < ApplicationController
  include Helper
  
  # 1. provision new machines in EC2
  # 2. knife bootstrap these machines
  def create
    @nodes = [] # shared variable, used to contain all fog node object
    @mutex = Mutex.new # lock
    
    number = params[:number_create].to_i
    logger.debug "::: Creating #{number} machine(s)..."
    
    flavor = ""
    if params[:flavor_create] == "small_create"
      flavor = "m1.small"
    elsif params[:flavor_create] == "medium_create"
      flavor = "m1.medium"
    else
      flavor = "m1.large"  
    end
    logger.debug "::: Flavor: #{flavor} selected..."
    
    state = get_state
    ami = state['chef_client_ami']
    key_pair = state['key_pair_name']
    security_group = state['security_group_name']
    
    node_name_array = []
    for i in 1..number do
      name = "cassandra-node" << i.to_s
      node_name_array << name
    end    
    logger.debug "::: Node names: "
    puts node_name_array
    
    # parallel
    # depends on the performance of KCSDB Server
    logger.debug "::: Provisioning #{number} machines with flavor #{flavor}..."
    results = Parallel.map(node_name_array, in_threads: node_name_array.size) do |node_name|
      provision_ec2_machine ami, flavor, key_pair, security_group, node_name
    end
    logger.debug "::: Provisioning #{number} machines with flavor #{flavor}... [OK]"
    
    token_array = calculate_token_position number
    logger.debug "::: Tokens: "
    puts token_array
    
    seeds = calculate_seed_list 0.5, number
    logger.debug "::: Seeds: "
    puts seeds

    logger.debug "::: Node IPs: "    
    node_ip_array = []
    @nodes.each {|node| node_ip_array << node.public_ip_address}
    # for j in 0..(@nodes.size - 1) do
      # node_ip_array << @nodes[j].public_ip_address
    # end
    puts node_ip_array
    
    logger.debug "::: Knife Bootstrap #{number} machines..." 
    bootstrap_array = []   
    for k in 1..(token_map.size) do
      tmp_array = []
      
      node_ip = node_ip_map[k-1] # for which node
      puts "Node IP: #{node_ip}"
      
      token = token_map[k-1] # which token position
      puts "Token: #{token}"
      
      node_name = "cassandra-node" << k.to_s
      puts "Node Name: #{node_name}"
      
      token_file = "#{Rails.root}/chef-repo/.chef/tmp/#{token}.sh"
      File.open(token_file,"w") do |file|
        file << "#!/usr/bin/env bash" << "\n"
        file << "echo #{token} | tee /home/ubuntu/token.txt" << "\n"
        file << "echo #{seeds} | tee /home/ubuntu/seeds.txt" << "\n"
      end

      tmp_array << node_ip
      tmp_array << token
      tmp_array << node_name
      bootstrap_array << tmp_array
    end
    results = Parallel.map(bootstrap_array, in_threads: bootstrap_array.size) do |block|
      system(knife_bootstrap block[0], block[1], block[2])
    end
    logger.debug "::: Knife Bootstrap #{number} machines... [OK]"    
    
    logger.debug "::: Deleting all token temporary files in KCSDB Server..."
    system "rm #{Rails.root}/chef-repo/.chef/tmp/*.sh"
    logger.debug "::: Deleting all token temporary files in KCSDB Server... [OK]"
  end
  
  # provision a new EC2 machine
  private
  def provision_ec2_machine ami, flavor, key_pair, security_group, name
    $stdout.sync = true
    
    ec2 = create_ec2
    
    logger.debug "=================================="
    logger.debug "Launching a new machine in AWS EC2"
    logger.debug "=================================="
    
    logger.debug "::: Now, launching a new machine with following configurations..."
    logger.debug "::: AMI: #{ami}"
    logger.debug "::: Flavor: #{flavor}"
    logger.debug "::: Key Pair: #{key_pair}"
    logger.debug "::: Security Group: #{security_group}"
    logger.debug "::: Name: #{name}"
    
    server_def = {
      image_id: ami,
      flavor_id: flavor,
      key_name: key_pair,
      groups: security_group
    }
    
    server = ec2.servers.create server_def
    logger.debug "::: Adding tag..."
    ec2.tags.create key: 'Name', value: name, resource_id: server.id

    logger.debug "::: Waiting for machine: #{server.id}..."
    server.wait_for { print "."; ready? }
    # the machine is updated with public IP address
    puts "\n"
    logger.debug "::: Waiting for machine: #{server.id}... [OK]"

    print "." until tcp_test_ssh(server.public_ip_address) { sleep 1 }

    # Adding a newly created server to the nodes list
    # lock    
    @mutex.synchronize do
      @nodes << server
    end
  end
  
  # knife bootstrap
  # node: the IP address of the machine to be bootstraped
  # token: which token position should the node have, the token is passed by KCSDB Server in form of a script for EC2
  # name: name of the node in Chef Server
  private
  def knife_bootstrap node, token, name
    $stdout.sync = true
    
    state = get_state
    # aws_access_key_id = state['aws_access_key_id']
    # aws_secret_access_key = state['aws_secret_access_key']
    # region = state['region']    
    # security_group_name = state['security_group_name']
    # chef_client_ami = state['chef_client_ami']
    # chef_client_flavor = flavor
    # chef_client_aws_ssh_key_id = state['chef_client_aws_ssh_key_id']
    chef_client_identity_file = state['chef_client_identity_file']
    chef_client_ssh_user = state['chef_client_ssh_user']
    chef_client_bootstrap_version = state['chef_client_bootstrap_version']
    chef_client_template_file = state['chef_client_template_file']
    chef_client_role = state['chef_client_role']
    
    no_checking = "-o 'UserKnownHostsFile /dev/null' -o StrictHostKeyChecking=no"

    logger.debug "::: Uploading the token file to the node: #{node}... "
    token_file = "#{Rails.root}/chef-repo/.chef/tmp/#{token}.sh"
    system "rvmsudo scp -i #{chef_client_identity_file} #{no_checking} #{token_file} #{chef_client_ssh_user}@#{node}:/home/#{chef_client_ssh_user}"
    logger.debug "::: Uploading the token file to the node: #{node}... [OK]"
    
    logger.debug "::: Executing the token file in the node: #{node}... "
    system "rvmsudo ssh -i #{chef_client_identity_file} #{no_checking} #{chef_client_ssh_user}@#{node} 'sudo bash #{token}.sh'"
    logger.debug "::: Executing the token file in the node: #{node}... [OK]"

    logger.debug "::: Knife bootstrapping a new machine..."
    
    # knife_ec2_bootstrap_string = ""
    knife_bootstrap_string = ""
       
    # knife_ec2_bootstrap_string << "rvmsudo knife ec2 server create "
    knife_bootstrap_string << "rvmsudo knife bootstrap #{node} "
    knife_bootstrap_string << "--config #{Rails.root}/chef-repo/.chef/conf/knife.rb "
    # knife_ec2_bootstrap_string << "--aws-access-key-id #{aws_access_key_id} "
    # knife_ec2_bootstrap_string << "--aws-secret-access-key #{aws_secret_access_key} "
    # knife_ec2_bootstrap_string << "--region #{region} "
    # knife_ec2_bootstrap_string << "--groups #{security_group_name} "
    # knife_ec2_bootstrap_string << "--image #{chef_client_ami} "
    # knife_ec2_bootstrap_string << "--flavor #{chef_client_flavor} "
    # knife_ec2_bootstrap_string << "--ssh-key #{chef_client_aws_ssh_key_id} "
    # knife_ec2_bootstrap_string << "--json-attributes \'#{chef_client_token_position}\' "
    # knife_ec2_bootstrap_string << "-VV "
    knife_bootstrap_string << "--identity-file #{chef_client_identity_file} "
    knife_bootstrap_string << "--ssh-user #{chef_client_ssh_user} "
    knife_bootstrap_string << "--bootstrap-version #{chef_client_bootstrap_version} "
    knife_bootstrap_string << "--template-file #{chef_client_template_file} "
    knife_bootstrap_string << "--run-list \'role[#{chef_client_role}]\' "
    # knife_bootstrap_string << "--user-data #{token} "
    knife_bootstrap_string << "--node-name \'#{name}\' "
    knife_bootstrap_string << "--yes "
    knife_bootstrap_string << "--no-host-key-verify "
    knife_bootstrap_string << "--sudo "
    
    logger.debug "::: The knife bootstrap command: #{knife_bootstrap_string}"
    knife_bootstrap_string
  end
  
  # token positions for all nodes in cassandra cluster
  private
  def calculate_token_position node_number
    logger.debug "::: Calculating tokens for #{node_number} nodes..."
    system "python #{Rails.root}/chef-repo/.chef/sh/tokentool.py #{node_number} > #{Rails.root}/chef-repo/.chef/tmp/tokens.json"
    json = File.open("#{Rails.root}/chef-repo/.chef/tmp/tokens.json","r")
    parser = Yajl::Parser.new
    hash = parser.parse json
    token_map = hash["0"].values
    token_map    
  end
  
  # seed list
  private
  def calculate_seed_list fraction, node_number
    logger.debug "::: Calculating seeds for #{node_number} nodes..."
    seeds = ""
    number_of_seeds = @nodes.size * fraction # a given fraction of all nodes in the cluster are seeds 
    for i in 0..number_of_seeds-1 do
      seeds << @nodes[i].private_ip_address << ","
    end
    seeds = seeds[0..-2] # delete the last comma
    seeds
  end
  
=begin
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
=end
end
