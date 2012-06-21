require "parseconfig"
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
end

