require 'helper'
class BenchmarkController < ApplicationController
  include Helper
  
  def run
    @status = ""
    
    benchmark_profile_url = params[:benchmark_profile_url]
    
    logger.debug "::: Getting the benchmark profile from the given source..."
    benchmark_profile_path = "#{Rails.root}/chef-repo/.chef/tmp/benchmark_profiles.yaml"
    system "curl -L #{benchmark_profile_url} -o #{benchmark_profile_path}"
    logger.debug "Getting the benchmark profile from the given source... [OK]"
    
    logger.debug "::: Parsing the benchmark profile..."
    benchmark_profiles = Psych.load(File.open benchmark_profile_path)
    
    # contain all keys of benchmark profiles
    # the keys are splitted in 2 groups
    # service key: service1, service2, etc...
    # profile key: profile1, profile2, etc...
    key_array = benchmark_profiles.keys
    logger.debug "::: Keys:"
    puts key_array
    
    # contain service1, service2, etc..
    # each service is a hash map, e.g. name => cassandra, attribute => { replication_factor => 3, partitioner => RandomPartitioner }
    service_array = []
    
    # contain profile1, profile2
    # each profile is a hash map, e.g. provider => aws, regions => { region1 => { name => us-east-1, machine_type => small, template => 3 service1+service2} }
    profile_array = []
    
    key_array.each do |key|
      if key.to_s.include? "service"
        service_array << benchmark_profiles[key]
      elsif key.to_s.include? "profile"
        profile_array << benchmark_profiles[key]
      else
        logger.debug "::: Profile is NOT conform. Please see the sample to write a good benchmark profile"
        exit 0
      end
    end
    
    logger.debug "::: Services:"
    puts service_array
    
    logger.debug "::: Profiles:"
    puts profile_array
    
    logger.debug "Parsing the benchmark profile... [OK]"

    profile_counter = 1
    profile_array.each do |profile| # each profile is a hash
      logger.debug "-----------------------------------------"
      logger.debug "::: Running profile #{profile_counter}..."
      logger.debug "-----------------------------------------"
      
      # Service Provision has to be called at first
      # to provision machines in cloud infrastructure
      
      cloud_config_hash = profile
      puts cloud_config_hash
#       
      # cloud_config_hash = Hash.new # attribute hash for Service Provision
      # cloud_config_hash['provider'] = nil
      # cloud_config_hash['regions'] = nil
      # tmp = Hash.new
#       
      # # iterate the profile hash
      # profile.each do |key, value|
        # if key.to_s.include? "provider"
          # cloud_config_hash['provider'] = value
        # else key.to
#           
        # end
      # end  
#       
#       
#       
      # tmp['provider'] = profile['provider']
      # cloud_config_hash.merge tmp
#       
      
      
      
      
      profile_counter += 1
    end    
    

    # # NOW, run each profile
    # profile_counter = 1
    # profile_array.each do |profile|
      # logger.debug "::: Running profile #{profile_counter}..."
#       
      # # each profile uses a dedicated provider
      # # aws | rackspace
      # provider = profile['provider']
      # logger.debug "Provider: #{provider}"
#       
      # region_array = []
      # region_counter = 1
      # region_found = true
#       
      # # seek regions
      # until ! region_found
        # if profile.key? "region#{region_counter}" 
          # region_array << profile["region#{region_counter}"]
          # region_counter = region_counter + 1
        # else
          # region_found = false
        # end
      # end
#       
      # logger.debug "Regions:"
      # puts region_array
#       
      # check_multiple_region = false
      # if region_array.size > 1
        # check_multiple_region = true
        # logger.debug "Deploying database cluster in multiple regions..."        
      # else
        # logger.debug "Deploying database cluster in single region..."
      # end
# 
      # profile_counter = profile_counter + 1
    # end


        
  end
  
  # used to detect how many machines should be created
  # described in template
  # e.g.: 3 service1+service3, 2 service2
  private
  def template_parse template_string
    found_number = 0
    test = template_string.split " "
    test.each do |el|
      # "3".to_i --> 3, "service1".to_i --> 0
      if el.to_i != 0
        found_number += el.to_i
      end 
    end
    found_number    
  end
  
  # --------------
  # Service Facade
  # --------------
  # used to invoke the corresponding service
  # name: the service to be invoked
  # atribute_hash: contains all needed attributes for the service 
  # 
  # ------------------
  # Supported Services
  # ------------------
  # 1.Provision (primary)
  #   Provision machines with the given parameters like provider, region, machine number, machine type.
  #
  # 2.Cassandra (primary)
  #   Deploy a Cassandra cluster in single/multiple region(s) with given database configuration parameters
  # 3.MongoDB (primary)
  #   Deploy a MongoDB cluster in single/multiple region(s) with given database configuration parameters
  # 
  # 4.YCSB (optional)
  #   Deploy a YCSB cluster to benchmark a given database cluster
  # 5.Ganglia (optional)
  #   Deploy Ganglia Agents (gmond) in each node of the given database cluster and Ganglia Central Monitoring (gmetad) in KCSDB Server  
  private
  def service name, attribute_hash
    if name == 'provsion'
      service_provision attribute_hash
    elsif name == 'cassandra'
      service_cassandra attribute_hash
    elsif name == 'mongodb'
      service_mongodb attribute_hash
    elsif name == 'ycsb'
      service_ycsb attribute_hash
    elsif name == 'ganglia'
      service_ganglia attribute_hash
    else
      logger.debug "::: Service: #{name} is not supported!"
      exit 0  
    end
  end
  
  # Service Provision
  # used to provision machines in parallel mode
  #
  # primary service
  # this service has to be called always at first to provision machines in cloud infrastructure
  # 
  # -- cloud_config_hash ---
  # provider: aws | rackspace
  # regions:
  #   region1: 
  #     name: us-east-1
  #     number: 4
  #     machine_type: m1.small
  #   region2:
  #     name: us-weast-1
  #     number: 2
  #     machine_type: m1.small
  # .....    
  private
  def service_provision cloud_config_hash
    logger.debug ":::::::::::::::::::::::::::::::::::::::::::"
    logger.debug "::: Service: Provision is being deployed..."
    logger.debug ":::::::::::::::::::::::::::::::::::::::::::"
    
    provider = cloud_config_hash['provider']
    region_hash = cloud_config_hash['regions']
    if provider == 'aws'
      service_provision_ec2 region_hash      
    elsif provider == 'rackspace'
      service_provision_rackspace region_hash
    else
      logger.debug "::: Provider: #{provider} is not supported!"
      exit 0
    end

    logger.debug "::::::::::::::::::::::::::::::::::::::::::::::::"
    logger.debug "::: Service: Provision is being deployed... [OK]"
    logger.debug "::::::::::::::::::::::::::::::::::::::::::::::::"
  end
  
  private
  def service_provision_ec2 cloud_config_hash
    logger.debug "::: Service: Provision EC2 is being deployed..."
    
    @nodes = [] # shared variable, used to contain all fog node object
    @mutex = Mutex.new # lock

    node_counter = 1
    cloud_config_hash.each do |region, values|
      region_name = values['name']
      machine_number = values['number'].to_i
      machine_flavor = values['machine_type']
      
      state = get_state
      if region_name == 'us-east-1'
        machine_ami = state['chef_client_ami_us_east_1']
      elsif region_name == 'us-west-1'
        machine_ami = state['chef_client_ami_us_west_1']
      else
        logger.debug "Region: #{region_name} is not supported!"
        exit 0
      end
      key_pair = state['key_pair_name']
      security_group = state['security_group_name']
      
      node_name_array = []
      machine_number.times do
        x = "cassandra-node-" << node_counter.to_s
        node_name_array << x
        node_counter = node_counter + 1
      end
      
      logger.debug "-------------------------"
      logger.debug "Region: #{region_name}"
      logger.debug "Machine number: #{machine_number}"
      logger.debug "Machine flavor: #{machine_flavor}"
      logger.debug "Machine image: #{machine_ami}"
      logger.debug "Key pair: #{key_pair}"
      logger.debug "Security group: #{security_group}"
      logger.debug "Node names: " ; puts node_name_array ;
      logger.debug "-------------------------"
      
      beginning_time = Time.now
      # parallel
      # depends on the performance of KCSDB Server
      results = Parallel.map(node_name_array, in_threads: node_name_array.size) do |node_name|
        provision_ec2_machine region_name, machine_ami, machine_flavor, key_pair, security_group, node_name
      end
      provisioning_time = Time.now
    
      logger.debug "::: PROVISIONING TIME for Region #{region_name}: #{provisioning_time - beginning_time} seconds"
    end  
    
    logger.debug "::: Service: Provision EC2 is being deployed... [OK]"
  end
  
  # provision a new EC2 machine
  # used for each thread
  private
  def provision_ec2_machine region, ami, flavor, key_pair, security_group, name
    $stdout.sync = true
    
    ec2 = create_fog_object 'aws', region
    
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
  
  private
  def service_provision_rackspace cloud_config_hash
    
  end

# ============================================================  
  private
  def service_cassandra cloud_config_hash, cassandra_config_hash
    logger.debug ":::::::::::::::::::::::::::::::::::::::::::"
    logger.debug "::: Service: Cassandra is being deployed..."
    logger.debug ":::::::::::::::::::::::::::::::::::::::::::"
    
    provider = cloud_config_hash['provider']
    machine_number = cloud_config_hash['machine_number']
    machine_type = cloud_config_hash['machine_type']
    
        
  end
  
  # 1. provision new machines in EC2
  # 2. knife bootstrap these machines
  def create
    recipe = "recipe[cassandra]"
    
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
    
    beginning_time = Time.now
    
    # parallel
    # depends on the performance of KCSDB Server
    logger.debug "::: Provisioning #{number} machines with flavor #{flavor}..."
    results = Parallel.map(node_name_array, in_threads: node_name_array.size) do |node_name|
      provision_ec2_machine ami, flavor, key_pair, security_group, node_name
    end
    logger.debug "::: Provisioning #{number} machines with flavor #{flavor}... [OK]"
    
    provisioning_time = Time.now
    
    logger.debug "::: PROVISIONING TIME: #{provisioning_time - beginning_time} seconds"
    
    token_array = calculate_token_position number
    logger.debug "::: Tokens: "
    puts token_array
    
    seeds = calculate_seed_list 0.5, number
    logger.debug "::: Seeds: "
    puts seeds

    logger.debug "::: Node IPs: "    
    node_ip_array = []
    @nodes.each {|node| node_ip_array << node.public_ip_address}
    puts node_ip_array
    
    logger.debug "::: Knife Bootstrap #{number} machines..." 
    bootstrap_array = []   
    for k in 1..(token_array.size) do
      tmp_array = []
      
      node_ip = node_ip_array[k-1] # for which node
      puts "Node IP: #{node_ip}"
      
      token = token_array[k-1] # which token position
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
      system(knife_bootstrap block[0], block[1], block[2], recipe)
    end
    logger.debug "::: Knife Bootstrap #{number} machines... [OK]"    
    
    logger.debug "::: Deleting all token temporary files in KCSDB Server..."
    system "rm #{Rails.root}/chef-repo/.chef/tmp/*.sh"
    logger.debug "::: Deleting all token temporary files in KCSDB Server... [OK]"
    
    bootstrap_time = Time.now
    
    logger.debug "::: BOOTSTRAP TIME: #{bootstrap_time - provisioning_time} seconds"
  end
  
  
  
  # knife bootstrap
  # node: the IP address of the machine to be bootstraped
  # token: which token position should the node have, the token is passed by KCSDB Server in form of a script for EC2
  # name: name of the node in Chef Server
  private
  def knife_bootstrap node, token, name, recipe
    $stdout.sync = true
    
    state = get_state
    chef_client_identity_file = state['chef_client_identity_file']
    chef_client_ssh_user = state['chef_client_ssh_user']
    chef_client_bootstrap_version = state['chef_client_bootstrap_version']
    chef_client_template_file = state['chef_client_template_file']
    
    no_checking = "-o 'UserKnownHostsFile /dev/null' -o StrictHostKeyChecking=no"

    logger.debug "::: Uploading the token file to the node: #{node}... "
    token_file = "#{Rails.root}/chef-repo/.chef/tmp/#{token}.sh"
    system "rvmsudo scp -i #{chef_client_identity_file} #{no_checking} #{token_file} #{chef_client_ssh_user}@#{node}:/home/#{chef_client_ssh_user}"
    logger.debug "::: Uploading the token file to the node: #{node}... [OK]"
    
    logger.debug "::: Executing the token file in the node: #{node}... "
    system "rvmsudo ssh -i #{chef_client_identity_file} #{no_checking} #{chef_client_ssh_user}@#{node} 'sudo bash #{token}.sh'"
    logger.debug "::: Executing the token file in the node: #{node}... [OK]"

    logger.debug "::: Knife bootstrapping a new machine..."
    
    knife_bootstrap_string = ""
       
    knife_bootstrap_string << "rvmsudo knife bootstrap #{node} "
    knife_bootstrap_string << "--config #{Rails.root}/chef-repo/.chef/conf/knife.rb "
    knife_bootstrap_string << "--identity-file #{chef_client_identity_file} "
    knife_bootstrap_string << "--ssh-user #{chef_client_ssh_user} "
    knife_bootstrap_string << "--bootstrap-version #{chef_client_bootstrap_version} "
    knife_bootstrap_string << "--template-file #{chef_client_template_file} "
    knife_bootstrap_string << "--run-list \'#{recipe}\' "
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
# ============================================================  
  
  
  
  
  
  
  
  
  
  
  
  
  private
  def service_ycsb attribute_array
    logger.debug "::: Service: YCSB is being deployed..."
  end
  
  private
  def service_gmond attribute_array
    logger.debug "::: Service: Gmond is being deployed..."
  end
  
  private
  def template_parse
    
  end
  
end