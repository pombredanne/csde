require 'helper'
class ChefNodeController < ApplicationController
  include Helper
  
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

  # stop all machines that KCSD manages
  # TODO stop the whole list
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
  # TODO: start a whole list
  def start
    machine_array = get_machine_array

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
      tmp_array = []
      machine_array.each do |server|
        if(server.flavor_id.to_s == flavor)
          tmp_array << server
        end
      end

      # start number machines
      # if the machine is already started, is OK
      delta = number - 1
      for i in 0..delta
        logger.debug "::: Starting machine: #{tmp_array[i].id}..."
        tmp_array[i].start
      end

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

  # 1. provision new machines in EC2
  # 2. knife bootstrap these machines
  def create
    
    # Knife Bootstrap
    # logger.debug "::: Loading Knife Bootstrap..."
    # Chef::Knife::Bootstrap.load_deps
    
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
    
    threads = []
    number.times do
      # Thread.new { create_server }
      thread = Thread.new { system(knife_ec2_bootstrap flavor)}
      threads << thread
    end
    
    # parallel bootstrap
    # Thread.list.each { |thread| thread.join if thread != Thread.main }
    threads.each {|t| t.join}
    logger.debug "::: END"

=begin
	  # TEST
    ec2 = init()

    stateKnife = getStateKnife()
    flavor = ""
    if(params[:flavor_create] == "small_create")
      flavor = "m1.small"
    elsif(params[:flavor_create] == "medium_create")
      flavor = "m1.medium"
    else
      flavor = "m1.large"
    end
    puts "#{flavor} selected..."
    stateKnife['knife[:flavor]'] = flavor
    updateStateKnife(stateKnife)

    number = params[:number_create].to_i
    puts "Creating #{number} machine(s)..."






    # get the parameters for knife ec2
    identity_file = stateKnife['knife[:identify_file]']
    ssh_user = stateKnife['knife[:ssh_user]']
    security_groups = stateKnife['knife[:security_groups]']
    #run_list = stateKnife['knife[:run_list]']

    # new parser with ParseConfig
    knife = ParseConfig.new

    # transform all values from knife.yml to the new config
    stateKnife.each_pair { |key, value|
      knife.add(key, value)
    }
    knife_rb = "#{Rails.root}/chef-repo/.chef/conf/knife.rb"
    knife_rb_dummy = "#{Rails.root}/chef-repo/.chef/knife.rb"
    knife_rb_file = File.open("#{knife_rb}","w")
    knife.write(knife_rb_file)
    knife_rb_file.close()

    knife_rb_file = File.open("#{knife_rb}", "r")
    knife_rb_file_dummy = File.open("#{knife_rb_dummy}", "w")

    #delete all = characters
    str = ""
    knife_rb_file.each do |line|

      if (line.to_s.start_with?("knife"))
        str += line.to_s
        str += "\n"
      else
        str += line.to_s.gsub("=","\s")
        str += "\n"
      end

    end

    knife_rb_file_dummy.write(str)
    knife_rb_file.close()
    knife_rb_file_dummy.close()

    # multi threaded
    #threads = []

    # bootstrap more machines using knife ec2
    
    #number.times do
      #system "knife ec2 server create -c #{knife_rb_dummy} --identity-file #{identity_file} --ssh-user #{ssh_user} --groups #{security_groups} --run-list #{run_list} --verbose"

      # SUN JDK 6 is already on the system

      #thread = Thread.new do
      #  system "knife ec2 server create -c #{knife_rb_dummy} --identity-file #{identity_file} --ssh-user #{ssh_user} --groups #{security_groups} --verbose"
      #  threads << thread
      #end

      #system "knife ec2 server create -c #{knife_rb_dummy} --identity-file #{identity_file} --ssh-user #{ssh_user} --groups #{security_groups} --verbose"
    #end

  	# TEST
  	threads = []
  	image = ec2.images["ami-a09c46c9"]
  	key_pair = ec2.key_pairs[identity_file]
  	security_group = ec2.security_groups[security_groups]
  	number.times do
  		thread = Thread.new do
  			instance = image.run_instance(:key_pair => key_pair,
                                        :security_groups => security_group,
                                        :instance_type => flavor)
  		end
  		threads << thread
  	end
  	threads.each {|thread| thread.join}
	


    #threads.each {|thread| thread.join}


    @status = "Create <strong>#{number}</strong> machines with flavor <strong>#{flavor}</strong>\n"
    @status += "\n"
    @status += "Click the <strong>back</strong> button below to come back dashboard\n"
=end
  end

  # return the machines that KCSDB manages in an array
  private
  def get_machine_array
    logger.debug "::: Getting all machines that KCSDB manages..."
    machine_array = []
    ec2 = create_ec2
    state = get_state
    key_pair_name = state['key_pair_name']
    chef_server_id = state['chef_server_id']
    
    ec2.servers.each do |server|
      # show all the instances that KCSD manages
      if server.key_name == key_pair_name
        # chef server is not including
        if server.id != chef_server_id
          # the machine is not terminated
          if server.state.to_s != "terminated"
            machine_array << server
          end
        end
      end
    end
    machine_array
  end
  
  # create a machine
  private
  def create_server
    ec2 = create_ec2
    state = get_state
    knife_config = get_knife_config
    
    $stdout.sync = true

    server_def = {
      image_id: knife_config['knife[:image]'],
      groups: knife_config['knife[:security_groups]'],
      flavor_id: knife_config['knife[:flavor]'],
      key_name: knife_config['knife[:aws_ssh_key_id]']
    }
    server = ec2.servers.create server_def
    server_id = server.id

    logger.debug "::: Waiting for machine: #{server_id}..."
    server.wait_for { print "."; ready? }
    puts "\n"


    server_ip = server.public_ip_address #TODO: private IP should be use    
    logger.debug "::: Checking if sshd in machine: #{server_id} with public IP: #{server_ip} is ready, please wait..."
    print "." until tcp_test_ssh(server_ip) { sleep 1 }

    # sleep 5
    # bootstrap_server(server).run
    system knife_bootstrap(server)

    # logger.debug "::: Adding the machine into list..."
    # puts "\n"
    # @server_list.push server.id

    rescue Fog::Compute::AWS::NotFound => error
    logger.debug "@@@@@@@@@@@@@ ERROR @@@@@@@@@@@@@"
    logger.debug error
    logger.debug "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

    rescue Fog::Compute::AWS::Error => error
    logger.debug "@@@@@@@@@@@@@ ERROR @@@@@@@@@@@@@"
    logger.debug error
    logger.debug "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  end


  # knife bootstrap
  private
  def knife_bootstrap server
    knife_bootstrap_string = ""
    knife_config = get_knife_config
    logger.debug "::: Bootstrapping #{server.id}..."
    logger.debug "::: ...with configurations:"
    
    dns_name = server.dns_name
    ssh_user = knife_config['knife[:ssh_user]']
    identity_file = knife_config['knife[:identity_file]']
    chef_node_name = server.id
    bootstrap_version = '10.12.0'
    template_file = knife_config['knife[:template_file]']

    knife_bootstrap_string << "knife bootstrap #{dns_name} "
    knife_bootstrap_string << "--config #{Rails.root}/chef-repo/.chef/conf/knife.rb "
    knife_bootstrap_string << "--identity-file #{identity_file} "
    knife_bootstrap_string << "--node-name #{chef_node_name} "
    knife_bootstrap_string << "--ssh-user #{ssh_user} "
    knife_bootstrap_string << "--bootstrap-version #{bootstrap_version} "
    knife_bootstrap_string << "--template-file #{template_file} "
    knife_bootstrap_string << "--sudo "
    knife_bootstrap_string << "--no-host-key-verify "
    
    logger.debug "::: The knife bootstrap command: #{knife_bootstrap_string}"
    knife_bootstrap_string
  end
  
  # knife ec2 server create
  private
  def knife_ec2_bootstrap flavor
    
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
    chef_client_aws_ssh_key_id = state['chef_client_aws_ssh_key_id']
    chef_client_template_file = state['chef_client_template_file']
   
    knife_ec2_bootstrap_string << "knife ec2 server create "
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
    knife_ec2_bootstrap_string << "--yes "
    knife_ec2_bootstrap_string << "--no-host-key-verify "
    # knife_ec2_bootstrap_string << "-VV "
    
    logger.debug "::: The knife bootstrap command: #{knife_ec2_bootstrap_string}"
    knife_ec2_bootstrap_string
  end

  
end
