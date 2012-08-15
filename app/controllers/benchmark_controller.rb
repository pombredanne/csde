require 'helper'
class BenchmarkController < ApplicationController
  include Helper
  
  def run
    @status = ""
    
    benchmark_profile_url = params[:benchmark_profile_url]
    
    logger.debug "----------------------------------------------------------"
    logger.debug "::: Getting the benchmark profile from the given source..."
    logger.debug "----------------------------------------------------------"
    benchmark_profile_path = "#{Rails.root}/chef-repo/.chef/tmp/benchmark_profiles.yaml"
    system "curl -L #{benchmark_profile_url} -o #{benchmark_profile_path}"
    logger.debug "Getting the benchmark profile from the given source... [OK]"
    
    
    logger.debug "------------------------------------"
    logger.debug "::: Parsing the benchmark profile..."
    logger.debug "------------------------------------"
    benchmark_profiles = Psych.load(File.open benchmark_profile_path)
    
    # contain all keys of benchmark profiles
    # the keys are split in 2 groups
    # service key: service1, service2, etc...
    # profile key: profile1, profile2, etc...
    key_array = benchmark_profiles.keys
    logger.debug "---------"
    logger.debug "::: Keys:"
    logger.debug "---------"
    puts key_array
    
    # contain service1, service2, etc..
    # each service is a hash map, e.g. name => cassandra, attribute => { replication_factor => 3, partitioner => RandomPartitioner }
    @service_array = []
    
    # contain profile1, profile2
    # each profile is a hash map, e.g. provider => aws, regions => { region1 => { name => us-east-1, machine_type => small, template => 3 service1+service2} }
    profile_array = []
    
    key_array.each do |key|
      if key.to_s.include? "service"
        @service_array << benchmark_profiles[key]
      elsif key.to_s.include? "profile"
        profile_array << benchmark_profiles[key]
      else
        logger.debug "::: Profile is NOT conform. Please see the sample to write a good benchmark profile"
        exit 0
      end
    end
    
    logger.debug "-------------"
    logger.debug "::: Services:"
    logger.debug "-------------"
    puts @service_array
    
    logger.debug "-------------"
    logger.debug "::: Profiles:"
    logger.debug "-------------"
    puts profile_array
    
    logger.debug "Parsing the benchmark profile... [OK]"

    profile_counter = 1
    profile_array.each do |profile| # each profile is a hash
      
      # --- profile ---
      # provider: aws
      # regions:
      #   region1:
      #     name: us-east-1
      #     machine_type: small
      #     template: 3 cassandra+gmond, 2 ycsb
      #   region2:
      #     name: us-west-1
      #     machine_type: small
      #     template: 5 cassandra+gmond, 4 ycsb
      # ...     
      logger.debug "-----------------------"
      logger.debug "::: RUNNING PROFILE #{profile_counter}..."
      logger.debug "-----------------------"
      
      logger.debug "-------------------------------------"
      logger.debug "::: The profile we'are running now..."
      logger.debug "-------------------------------------"
      puts profile
      
      @db_regions = Hash.new 
      # shared variable, used to contain all fog objects in each region
      # relevant information for DATABASE NODES and GMOND AGENTS which are installed in these nodes 
      # --- @db_regions ---
      # region1:
      #   name: us-east-1
      #   ips: [1,2,3]
      #   seeds: 1,2,4
      #   tokens: [0,121212,352345]
      # region2:
      #   name: us-west-1
      #   ips: [4,5]
      #   seeds: 1,2,4
      #   tokens: [4545, 32412341234]
      # attributes:
      #   replication_factor: 2,2
      
      @bench_regions = Hash.new
      # shared variable, used to contain all fog objects in each region
      # relevant information for BENCHMARK NODES and GMOND AGENTS which are installed in these nodes
      # ---@bench_regions ---
      # region1:
      #   name: us-east-1
      #   ips: [1,2,3]
      # region2:
      #   name: us-west-1
      #   ips: [4,5]
      # attributes:
      #   workload_model: hotspot
      
      # Service Provision has to be called at first
      # to provision machines in cloud infrastructure
      # profile hash is used to fill @db_regions hash
      logger.debug "-----------------------------------------------------------"
      logger.debug "STEP 1: Invoking Service [Provision] for Database Cluster..."
      logger.debug "-----------------------------------------------------------"
      if profile['regions']['region1']['template'].to_s.include? "cassandra"
        service 'provision', profile, 'cassandra' # provision machines with flag 'cassandra' 
      elsif profile['regions']['region1']['template'].to_s.include? "mongodb"
        service 'provision', profile, 'mongodb'
      else
        logger.debug "Database Service Cassandra OR MongoDB, just one of these!"
        exit 0
      end
      # service 'provision', profile

      # --- @db_regions ---
      #   region1:
      #     name: us-east-1
      #     ips: [1,2,3]
      #   region2:
      #     name: us-west-1
      #     ips: [4,5]
      #....
      logger.debug "----------------------------------"
      logger.debug "::: Node IPs for Database Cluster:"
      logger.debug "----------------------------------"    
      @db_regions.each do |key,values|
        logger.debug "Region: #{values['name']}"
        logger.debug "IPs: #{values['ips']}"       
      end
      
      # clone the parameters
      # database_config_hash = @regions
      logger.debug "-----------------------------------------------------------"
      logger.debug "STEP 2: Invoking Service [Database] for Database Cluster..."
      logger.debug "-----------------------------------------------------------"
      
      if profile['regions']['region1']['template'].to_s.include? "cassandra"
        # service 'cassandra', database_config_hash
        service 'cassandra', @db_regions, nil
      elsif profile['regions']['region1']['template'].to_s.include? "mongodb"
        # service 'mongodb', database_config_hash
        service 'mongodb', @db_regions, nil
      else
        logger.debug "Database Service Cassandra OR MongoDB, just one of these!"
        exit 0  
      end      
      
      logger.debug "-------------------------------------------------------------"
      logger.debug "STEP 3: Invoking Service [Provision] for Benchmark Cluster..."
      logger.debug "-------------------------------------------------------------"
      service 'provision', profile, 'ycsb' # provision machines with flag 'ycsb'
      
      # --- @bench_regions ---
      #   region1:
      #     name: us-east-1
      #     ips: [1,2,3]
      #   region2:
      #     name: us-west-1
      #     ips: [4,5]
      #....
      logger.debug "-----------------------------------"
      logger.debug "::: Node IPs for Benchmark Cluster:"
      logger.debug "-----------------------------------"    
      @bench_regions.each do |key,values|
        logger.debug "Region: #{values['name']}"
        logger.debug "IPs: #{values['ips']}"       
      end
      
      logger.debug "----"
      logger.debug "TEST"
      logger.debug "----"
      logger.debug "@db_regions:"
      puts @db_regions
      logger.debug "@bench_regions:"
      puts @bench_regions
      
      logger.debug "--------------------------------------------------------"
      logger.debug "STEP 4: Invoking Service [YCSB] for Benchmark Cluster..."
      logger.debug "--------------------------------------------------------"
      service 'ycsb', @bench_regions, nil
      
      
      profile_counter += 1
    end    
  end
  
  # used to detect how many machines should be created for DATABASE service
  # convention: first place in template
  # e.g.: 3 cassandra+gmond, 2 ycsb --> 3
  private
  def template_parse_to_find_machine_number_for_database_service template_string
    found_number = 0
    test = template_string.split " "
    found_number = test[0].to_i
    found_number
  end

  # used to detect how many machines should be created for BENCHMARK service
  # convention: direct after the comma
  # e.g.: 3 cassandra+gmond, 2 ycsb --> 2
  private
  def template_parse_to_find_machine_number_for_benchmark_service template_string
    found_number = 0
    test = template_string.split ","
    test[1] = test[1].to_s.strip # delete the white spaces
    found_number = test[1].to_s.split(" ")[0]
    found_number
  end

  # private
  # def template_parse_to_machine_number template_string
    # found_number = 0
    # test = template_string.split " "
    # test.each do |el|
      # # "3".to_i --> 3, "service1".to_i --> 0
      # if el.to_i != 0
        # found_number += el.to_i
      # end 
    # end
    # found_number    
  # end
  
  # --- template_string ---
  # 3 cassandra+gmond, 2 ycsb 
  private
  def template_parse_to_find_service template_string
    sub_cluster_arr = []
    
    # ycsb is needed
    if template_string.to_s.include? ","
      sub_cluster_arr = template_string.to_s.split ","
      
      # delete the first and last white spaces in each sub cluster
      for i in 0..(sub_cluster_arr.size - 1)
        sub_cluster_arr[i] = sub_cluster_arr[i].to_s.strip
      end
    
    # ycsb is not needed
    else
      sub_cluster_arr << template_string.to_s.strip
    end

    # validation
    # cassandra | mongoDB 
    if (sub_cluster_arr[0].to_s.include? "cassandra") && (sub_cluster_arr[0].to_s.include? "mongodb")
      logger.debug "::: Cassandra OR MongoDB, not the parallel!"
      exit 0
    end

    sub_cluster_arr
    # sub_cluster_arr[0]: database sub cluster
    # sub_cluster_arr[1]: benchmark sub cluster
  end
  
  # --------------
  # Service Facade
  # --------------
  # used to invoke the corresponding service
  # name: the service to be invoked
  # atribute_hash: contains all needed attributes for the service
  # flag: optional for service calls
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
  def service name, attribute_hash, flag
    # SERVICE_ID: 1
    if name == 'provision'
      service_provision attribute_hash, flag

    # SERVICE_ID: 2    
    elsif name == 'cassandra'
      service_cassandra attribute_hash
    elsif name == 'mongodb'
      service_mongodb attribute_hash

    # SERVICE_ID: 3
    elsif name == 'ycsb'
      service_ycsb attribute_hash
    
    # SERVICE_ID: 4
    elsif name == 'ganglia'
      service_ganglia attribute_hash
    else
      logger.debug "::: Service: #{name} is not supported!"
      exit 0  
    end
  end
  
  # -------------------------------------------------------------------------------------------- #
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
  #     machine_type: small     
  #     template: 3 cassandra, 2 ycsb
  #     
  #   region2:
  #     name: us-weast-1
  #     machine_type: small     
  #     template: 2 cassandra
  # .....    
  # SERVICE_ID: 1
  private
  def service_provision cloud_config_hash, flag
    logger.debug ":::::::::::::::::::::::::::::::::::::::::::"
    logger.debug "::: Service: Provision is being deployed..."
    logger.debug ":::::::::::::::::::::::::::::::::::::::::::"
    
    provider = cloud_config_hash['provider']
    region_hash = cloud_config_hash['regions']
    
    # SERVICE_ID: 1.1
    if provider == 'aws'
      service_provision_ec2 region_hash, flag      
    
    # SERVICE_ID: 1.2
    elsif provider == 'rackspace'
      service_provision_rackspace region_hash, flag
    else
      logger.debug "::: Provider: #{provider} is not supported!"
      exit 0
    end

    logger.debug "::::::::::::::::::::::::::::::::::::::::::::::::"
    logger.debug "::: Service: Provision is being deployed... [OK]"
    logger.debug "::::::::::::::::::::::::::::::::::::::::::::::::"
  end
  
  # provision EC2 machine for database service and benchmark service
  # --> defined via the flag variable
  #
  # SERVICE_ID: 1.1
  private
  def service_provision_ec2 cloud_config_hash, flag
    logger.debug ":::::::::::::::::::::::::::::::::::::::::::::::"
    logger.debug "::: Service: Provision EC2 is being deployed..."
    logger.debug ":::::::::::::::::::::::::::::::::::::::::::::::"
    
    # @db_regions = Hash.new 
    # shared variable, used to contain all fog objects in each region
    # relevant information for DATABASE NODES and the GMOND AGENTS which are installed in these nodes 
    # --- @db_regions ---
    # region1:
    #   name: us-east-1
    #   ips: [1,2,3]
    # region2:
    #   name: us-west-1
    #   ips: [4,5]
    #....
    
    # @bench_regions = Hash.new
    # shared variable, used to contain all fog objects in each region
    # relevant information for BENCHMARK NODES
    # ---@bench_regions ---
    # region1:
    #   name: us-east-1
    #   ips: [1,2,3]
    # region2:
    #   name: us-west-1
    #   ips: [4,5]
    #....

    node_counter = 1
    cloud_config_hash.each do |region, values|
      region_name = values['name']
      machine_flavor = "m1." + values['machine_type']
      
      # calculate the machine number for this region from template
      # depends on the flag
      machine_number = 0
      if flag == "cassandra" or flag == "mongodb"
        machine_number = template_parse_to_find_machine_number_for_database_service(values['template']).to_i       
      elsif flag == "ycsb"
        machine_number = template_parse_to_find_machine_number_for_benchmark_service(values['template']).to_i
      end
      
      # region1:
      #   name: us-east-1
      name = Hash.new
      name['name'] = region_name
      
      if flag == "cassandra" or flag == "mongodb"
        @db_regions[region] = name
      elsif flag == "ycsb"
        @bench_regions[region] = name
      end
      # @regions[region] = name
      
      state = get_state
      if region_name == 'us-east-1'
        machine_ami = state['chef_client_ami_us_east_1']
      elsif region_name == 'us-west-1'
        machine_ami = state['chef_client_ami_us_west_1']
      elsif region_name == 'us-west-2'
        machine_ami = state['chef_client_ami_us_west_2']
      elsif region_name == 'eu-west-1'
        machine_ami = state['chef_client_ami_eu_west_1']
      else
        logger.debug "Region: #{region_name} is not supported!"
        exit 0
      end
      key_pair = state['key_pair_name']
      security_group = state['security_group_name']
      
      node_name_array = []
      machine_number.times do
        x = "#{flag}-node-" << node_counter.to_s
        # x = "cassandra-node-" << node_counter.to_s
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

      # BEFORE, @nodes contains nothing
      @nodes = [] # shared variable, used to contain all node IP in each region
      @mutex = Mutex.new # lock

      # parallel
      # depends on the performance of KCSDB Server
      results = Parallel.map(node_name_array, in_threads: node_name_array.size) do |node_name|
        provision_ec2_machine region_name, machine_ami, machine_flavor, key_pair, security_group, node_name
      end
      provisioning_time = Time.now
      
      # AFTER, @nodes contains IPs, filled by provision_ec2_machine
      ips = Hash.new
      ips['ips'] = @nodes
      if flag == "cassandra" or flag == "mongodb"
        @db_regions[region] = @db_regions[region].merge ips
      elsif flag == "ycsb"
        @bench_regions[region] = @bench_regions[region].merge ips
      end
      # @regions[region] = @regions[region].merge ips
      
      # region1:
      #   name: us-east-1
      #   ips: [1,2,3]
    
      logger.debug "::: PROVISIONING TIME for Region #{region_name}: #{provisioning_time - beginning_time} seconds"
    end  
    
    logger.debug "::::::::::::::::::::::::::::::::::::::::::::::::::::"
    logger.debug "::: Service: Provision EC2 is being deployed... [OK]"
    logger.debug "::::::::::::::::::::::::::::::::::::::::::::::::::::"
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
      @nodes << server.public_ip_address
    end
  end
  
  # SERVICE_ID: 1.2
  private
  def service_provision_rackspace cloud_config_hash, flag
    
  end
  
  # provision a new Rackspace machine
  # used for each thread
  private
  def provision_rackspace_machine
    
  end
  # -------------------------------------------------------------------------------------------- #
  
  # -------------------------------------------------------------------------------------------- #
  # Service Cassandra
  # database service
  # used to deploy a database cluster in single/multiple region(s) in parallel mode
  #
  # primary service
  # a database service (Cassandra | MongoDB) has always to be called
  #
  # --- (should be) cassandra_config_hash ---
  # region1:
  #   name: us-east-1
  #   ips: [1,2,3]
  #   seeds: 1,2,4 (will be calculated)
  #   tokens: [0,121212,352345] (will be calculated)
  # region2:
  #   name: us-west-1
  #   ips: [4,5]
  #   seeds: 1,2,4 (will be calculated)
  #   tokens: [4545, 32412341234] (will be calculated)
  # attributes:
  #   replication_factor: 2,2 (will be fetched)
  # SERVICE_ID: 2
  private
  def service_cassandra cassandra_config_hash
    logger.debug ":::::::::::::::::::::::::::::::::::::::::::"
    logger.debug "::: Service: Cassandra is being deployed..."
    logger.debug ":::::::::::::::::::::::::::::::::::::::::::"
    
    logger.debug "--------------------------"
    logger.debug "::: Cassandra Config Hash:"
    logger.debug "--------------------------"
    puts cassandra_config_hash
    
    # calculate the tokens for nodes in single/multiple regions
    # SERVICE_ID: 2.1
    cassandra_config_hash = calculate_token_position cassandra_config_hash
    # logger.debug "Cassandra Config Hash (incl. Tokens)"
    # puts cassandra_config_hash

    # calculate the seeds for nodes in single/multiple regions
    # SERVICE_ID: 2.2
    cassandra_config_hash = calculate_seed_list cassandra_config_hash    
    # logger.debug "Cassandra Config Hash (incl. Tokens and Seeds)"
    # puts cassandra_config_hash
    
    # fetch the attributes for nodes
    # SERVICE_ID: 2.3
    cassandra_config_hash = fetch_attributes_for_cassandra cassandra_config_hash
    logger.debug "-----------------------------------------------------------"
    logger.debug "::: Cassandra Config Hash (incl. Tokens, Seeds, Attributes)"
    logger.debug "-----------------------------------------------------------"
    puts cassandra_config_hash
    
    # check multiple regions or single region
    single_region_hash = Hash.new
    if cassandra_config_hash.has_key? "region2" # at least region2 exists
      single_region_hash['single_region'] = 'false'
    else
      single_region_hash['single_region'] = 'true'
    end
    
    # update default.rb
    # SERVICE_ID: 2.4
    default_rb_hash = cassandra_config_hash['attributes'].merge single_region_hash    
    update_default_rb_of_cookbooks default_rb_hash
        
    # deploy cassandra
    # SERVICE_ID: 2.5
    deploy_cassandra cassandra_config_hash
    
    # for single region mode only
    # make a small pause, the cassandra server needs a little time to be ready
    if single_region_hash['single_region'] == 'true'
      sleep 60
    end
    
    # configure cassandra via cassandra-cli
    # SERVICE_ID: 2.6
    configure_cassandra cassandra_config_hash
    
    logger.debug "::::::::::::::::::::::::::::::::::::::::::::::::"
    logger.debug "::: Service: Cassandra is being deployed... [OK]"
    logger.debug "::::::::::::::::::::::::::::::::::::::::::::::::"    
  end
  
  # token positions for all node in single/multiple regions
  #
  # --- cassandra_config_hash ---
  # region1:
  #   name: us-east-1
  #   ips: [1,2,3]
  # region2:
  #   name: us-west-1
  #   ips: [4,5]
  # SERVICE_ID: 2.1
  private
  def calculate_token_position cassandra_config_hash 
    logger.debug "-------------------------"
    logger.debug "::: Calculating tokens..."
    logger.debug "-------------------------"
    
    # generate parameter for tokentool.py
    param = ""
    cassandra_config_hash.each do |key, values|
      logger.debug "Region: #{values['name']} / Nodes: #{values['ips'].size}"
      param << values['ips'].size.to_s << " "
    end  

    # call tokentool.py    
    system "python #{Rails.root}/chef-repo/.chef/sh/tokentool.py #{param} > #{Rails.root}/chef-repo/.chef/tmp/tokens.json"
    json = File.open("#{Rails.root}/chef-repo/.chef/tmp/tokens.json","r")
    parser = Yajl::Parser.new
    token_hash = parser.parse json
    # {
      # "0": {
          # "0": 0, 
          # "1": 56713727820156410577229101238628035242, 
          # "2": 113427455640312821154458202477256070485
      # }, 
      # "1": {
          # "0": 28356863910078205288614550619314017621, 
          # "1": 85070591730234615865843651857942052863, 
          # "2": 141784319550391026443072753096570088106
      # }
    # }

    # adding tokens into cassandra_config_hash
    token_hash.each do |key, values|
      tmp_arr = values.values # tmp_arr contains tokens for the region
      t = Hash.new
      t['tokens'] = tmp_arr
      cassandra_config_hash["region#{key.to_i + 1}"] = cassandra_config_hash["region#{key.to_i + 1}"].merge t
    end  

    cassandra_config_hash
  end
  
  # seed list for each region
  #
  # --- cassandra_config_hash ---
  # region1:
  #   name: us-east-1
  #   ips: [1,2,3]
  # region2:
  #   name: us-west-1
  #   ips: [4,5]
  # SERVICE_ID: 2.2
  private
  def calculate_seed_list cassandra_config_hash
    # 50% nodes are seeds in each region
    # at least one node
    fraction = 0.5
    
    logger.debug "------------------------"
    logger.debug "::: Calculating seeds..."
    logger.debug "------------------------"
    seeds = ""
    cassandra_config_hash.each do |key, values|
      logger.debug "Region: #{values['name']} / Nodes: #{values['ips'].size}"
      
      if values['ips'].size == 1 # only one node, this node is seed 
        seeds << values['ips'][0] << ","
      else # more than one node
        number_of_seeds = values['ips'].size * fraction
        for i in 0..(number_of_seeds - 1) do
          seeds << values['ips'][i] << ","
        end
      end
    end
    seeds = seeds[0..-2] # delete the last comma
    
    cassandra_config_hash.each do |key,value|
      seeds_hash = Hash.new
      seeds_hash['seeds'] = seeds
      cassandra_config_hash[key] = cassandra_config_hash[key].merge seeds_hash
    end

    cassandra_config_hash
  end
  
  # fetch attributes from definitions
  #
  # --- cassandra_config_hash ---
  # region1:
  #   name: us-east-1
  #   ips: [1,2,3]
  # region2:
  #   name: us-west-1
  #   ips: [4,5]
  # SERVICE_ID: 2.3
  private
  def fetch_attributes_for_cassandra cassandra_config_hash
    @service_array.each do |service|
      if service['name'] == 'cassandra'
        cassandra_config_hash['attributes'] = service['attributes']
      end
    end
    cassandra_config_hash  
  end
  
  # update the parameters that are written in cookbooks/cassandra/attributes/default.rb
  # and upload cookbooks once again
  #
  # --- param_hash ---
  # seeds: 1,2,3
  # ...
  # SERVICE_ID: 2.4
  private
  def update_default_rb_of_cookbooks param_hash
    logger.debug "------------------------------------------------"
    logger.debug "::: Updating default.rb of cassandra cookbook..."
    logger.debug "------------------------------------------------"
    file_name = "#{Rails.root}/chef-repo/cookbooks/cassandra/attributes/default.rb"
    default_rb = File.read file_name
    param_hash.each do |key, value|
      default_rb.gsub!(/.*default\[:cassandra\]\[:#{key}\].*/, "default[:cassandra][:#{key}] = \'#{value}\'")
    end  
    File.open(file_name,'w') {|f| f.write default_rb }
    
    logger.debug "-----------------------------------------"
    logger.debug "::: Uploading cookbooks to Chef Server..."
    logger.debug "-----------------------------------------"
    system "rvmsudo knife cookbook upload cassandra --config #{Rails.root}/chef-repo/.chef/conf/knife.rb"
  end
  
  # deploy cassandra in each region in parallel mode (for each region)
  #
  # --- cassandra_config_hash ---
  # region1:
  #   name: us-east-1
  #   ips: [1,2,3]
  #   seeds: 1,2,4
  #   tokens: [0,121212,352345]
  # region2:
  #   name: us-west-1
  #   ips: [4,5]
  #   seeds: 1,2,4
  #   tokens: [4545, 32412341234]
  # attributes:
  #   replication_factor: 2,2  
  # SERVICE_ID: 2.5
  private
  def deploy_cassandra cassandra_config_hash
    logger.debug "-----------------------------------------"
    logger.debug "::: Deploying Cassandra in each region..."
    logger.debug "-----------------------------------------"
    recipe = "recipe[cassandra]"
    region_counter = 1
    cassandra_node_counter = 1
    until ! cassandra_config_hash.has_key? "region#{region_counter}" do
      logger.debug "-------------------------------------"
      logger.debug "::: Deploying Cassandra in region #{region_counter}"
      logger.debug "-------------------------------------"
      current_region = cassandra_config_hash["region#{region_counter}"]
      
      node_ip_array = current_region['ips']
      token_array = current_region['tokens']
      seeds = current_region['seeds']
      
      bootstrap_array = []
      for j in 0..(node_ip_array.size - 1) do
        tmp_array = []
        
        node_ip = node_ip_array[j] # for which node
        puts "Node IP: #{node_ip}"
      
        token = token_array[j] # which token position
        puts "Token: #{token}"
        
        node_name = "cassandra-node-" << cassandra_node_counter.to_s
        cassandra_node_counter += 1
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
      
      logger.debug "-------------------------------------------------------"
      logger.debug "::: Knife Bootstrap #{bootstrap_array.size} machines..."
      logger.debug "-------------------------------------------------------"
      results = Parallel.map(bootstrap_array, in_threads: bootstrap_array.size) do |block|
        system(knife_bootstrap block[0], block[1], block[2], recipe, current_region['name'])
      end
      logger.debug "Knife Bootstrap #{bootstrap_array.size} machines... [OK]"
      
      logger.debug "---------------------------------------------------------"
      logger.debug "::: Deleting all token temporary files in KCSDB Server..."
      logger.debug "---------------------------------------------------------"
      system "rm #{Rails.root}/chef-repo/.chef/tmp/*.sh"
      logger.debug "Deleting all token temporary files in KCSDB Server... [OK]"
      
      region_counter += 1
    end
  end
  
  # knife bootstrap
  # node: the IP address of the machine to be bootstraped
  # token: which token position should the node have, the token is passed by KCSDB Server in form of a script for EC2
  # name: name of the node in Chef Server
  # SERVICE_ID: 2.5.1
  private
  def knife_bootstrap node, token, name, recipe, region
    $stdout.sync = true
    
    state = get_state

    key_pair = state['key_pair_name']
    chef_client_identity_file = "#{Rails.root}/chef-repo/.chef/pem/#{key_pair}-#{region}.pem"
    
    chef_client_ssh_user = state['chef_client_ssh_user']
    chef_client_bootstrap_version = state['chef_client_bootstrap_version']
    chef_client_template_file = state['chef_client_template_file']
    
    no_checking = "-o 'UserKnownHostsFile /dev/null' -o StrictHostKeyChecking=no"

    logger.debug "-----------------------------------------------------"
    logger.debug "::: Uploading the token file to the node: #{node}... "
    logger.debug "-----------------------------------------------------"
    token_file = "#{Rails.root}/chef-repo/.chef/tmp/#{token}.sh"
    system "rvmsudo scp -i #{chef_client_identity_file} #{no_checking} #{token_file} #{chef_client_ssh_user}@#{node}:/home/#{chef_client_ssh_user}"
    logger.debug "::: Uploading the token file to the node: #{node}... [OK]"
    
    logger.debug "-----------------------------------------------------"
    logger.debug "::: Executing the token file in the node: #{node}... "
    logger.debug "-----------------------------------------------------"
    system "rvmsudo ssh -i #{chef_client_identity_file} #{no_checking} #{chef_client_ssh_user}@#{node} 'sudo bash #{token}.sh'"
    logger.debug "::: Executing the token file in the node: #{node}... [OK]"
    
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
    
    logger.debug "----------------------------------------"
    logger.debug "::: Knife bootstrapping a new machine..."
    logger.debug "::: The knife bootstrap command:"
    logger.debug "----------------------------------------" 
    logger.debug knife_bootstrap_string
    knife_bootstrap_string
  end
  
  # configure cassandra via cassandra-cli
  #
  # --- cassandra_config_hash ---
  # region1:
  #   name: us-east-1
  #   ips: [1,2,3]
  #   seeds: 1,2,4
  #   tokens: [0,121212,352345]
  # region2:
  #   name: us-west-1
  #   ips: [4,5]
  #   seeds: 1,2,4
  #   tokens: [4545, 32412341234]
  # attributes:
  #   replication_factor: 2,1
  # SERVICE_ID: 2.6
  private
  def configure_cassandra cassandra_config_hash
    logger.debug "------------------------------------"
    logger.debug "::: Configuring Cassandra cluster..."
    logger.debug "------------------------------------"
    
    # delete the recipe[cassandra] in cassandra-node-1
    system "rvmsudo knife node run_list remove cassandra-node-1 'recipe[cassandra]' --config #{Rails.root}/chef-repo/.chef/conf/knife.rb"
    
    # update replication_factor
    rep_fac_arr = []
    if cassandra_config_hash['attributes']['replication_factor'].to_s.include? "," # multiple regions
      rep_fac_arr = cassandra_config_hash['attributes']['replication_factor'].to_s.split ","
      
      # delete the first and last white spaces
      for i in 0..(rep_fac_arr.size - 1)
        rep_fac_arr[i] = rep_fac_arr[i].to_s.strip
      end
    else # single region
      rep_fac_arr << cassandra_config_hash['attributes']['replication_factor'].to_s.strip
    end

    # us-east-1:2,us-west-1:1
    for i in 0..(rep_fac_arr.size - 1)
      rep_fac_arr[i] = cassandra_config_hash["region#{i + 1}"]['name'] + ":" + rep_fac_arr[i]  
    end
    replication_factor = ""
    rep_fac_arr.each do |rep|
      replication_factor << rep << ","
    end
    replication_factor = replication_factor[0..-2] # delete the last comma
    
    rep_fac_hash = Hash.new
    rep_fac_hash['replication_factor'] = replication_factor
    
    update_default_rb_of_cookbooks rep_fac_hash
    
    system "rvmsudo knife node run_list add cassandra-node-1 'recipe[cassandra::configure_cluster]' --config #{Rails.root}/chef-repo/.chef/conf/knife.rb"
    
    # invoke the recipe[cassandra::configure_cluster]
    state = get_state
    ssh_user = state['chef_client_ssh_user']
    key_pair = state['key_pair_name']
    region = cassandra_config_hash['region1']['name'] # cassandra-node-1 is always in region1
    
    cmd = ""
    cmd << "rvmsudo knife ssh name:cassandra-node-1 --config #{Rails.root}/chef-repo/.chef/conf/knife.rb "
    cmd << "--ssh-user #{ssh_user} "
    cmd << "--identity-file #{Rails.root}/chef-repo/.chef/pem/#{key_pair}-#{region}.pem "
    cmd << "--attribute ec2.public_hostname "
    cmd << "\'sudo chef-client\'"
    
    puts cmd
    
    system cmd
    # system "rvmsudo knife ssh name:cassandra-node-1 --config #{Rails.root}/chef-repo/.chef/conf/knife.rb -x #{ssh_user} -i #{Rails.root}/chef-repo/.chef/pem/#{key_pair}-#{region}.pem -a ec2.public_hostname 'sudo chef-client'"
  end
  # -------------------------------------------------------------------------------------------- #
 
  # -------------------------------------------------------------------------------------------- # 
  # install ycsb cluster in each region
  #
  # uses 2 shared hash maps
  #
  # --- @db_regions ---
  # region1:
  #   name: us-east-1
  #   ips: [1,2,3]
  #   seeds: 1,2,4
  #   tokens: [0,121212,352345]
  # region2:
  #   name: us-west-1
  #   ips: [4,5]
  #   seeds: 1,2,4
  #   tokens: [4545, 32412341234]
  #
  # ---@bench_regions = ycsb_config_hash---
  # region1:
  #   name: us-east-1
  #   ips: [1,2,3]
  # region2:
  #   name: us-west-1
  #   ips: [4,5]
  # attributes:
  #   workload_model: hotspot
  private
  def service_ycsb ycsb_config_hash
    logger.debug "--------------------------------------"
    logger.debug "::: Service: YCSB is being deployed..."
    logger.debug "--------------------------------------"
        
    logger.debug "-----------------"    
    logger.debug "YCSB Config Hash:"
    logger.debug "-----------------"
    puts ycsb_config_hash
    
    # fetch attributes
    ycsb_config_hash = fetch_attributes_for_ycsb ycsb_config_hash
    
    logger.debug "------------------------------------"    
    logger.debug "YCSB Config Hash (incl. Attributes):"
    logger.debug "------------------------------------"
    puts ycsb_config_hash
    
    
  end
  
  # fetch attributes from definitions
  #
  # --- ycsb_config_hash ---
  # region1:
  #   name: us-east-1
  #   ips: [1,2,3]
  # region2:
  #   name: us-west-1
  #   ips: [4,5]
  private
  def fetch_attributes_for_ycsb ycsb_config_hash
    @service_array.each do |service|
      if service['name'] == 'ycsb'
        ycsb_config_hash['attributes'] = service['attributes']
      end
    end
    ycsb_config_hash  
  end
  # --------------------------------------------------------------------------------------------#
  
  # -------------------------------------------------------------------------------------------- #
  private
  def service_mongodb mongodb_config_hash
    
  end
  # -------------------------------------------------------------------------------------------- #  
  
  private
  def service_gmond attribute_array
    logger.debug "::: Service: Gmond is being deployed..."
  end
end