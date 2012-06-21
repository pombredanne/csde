require "State"
require "Ec2"
require "parseconfig"
class ChefNodeController < ApplicationController
  include State
  include Ec2

  # count how many machines are available in the infrastructure
  def check
    machine_array = getMachineArray()

    small = 0
    medium = 0
    large = 0

    machine_array.each do |instance|
      if(instance.instance_type == "m1.small")
          small += 1
      elsif(instance.instance_type == "m1.medium")
          medium += 1
      elsif(instance.instance_type == "m1.large")
          large += 1
      end
    end

    @status = "Now we have <strong>#{machine_array.size}</strong> machine(s) in the infrastructure\n"
    @status += "\n"
    @status += "<strong>Small</strong> machines: #{small}\n"
    @status += "<strong>Medium</strong> machines: #{medium}\n"
    @status += "<strong>Large</strong> machines: #{large}\n"
    #@status += "\n"
    #@status += "Please click <strong>Show all machines</strong> to get more details\n"
    #@status += "\n"
    #@status += "Stop all machines by clicking <strong>Stop all machines</strong> before you want to deploy Cassandra\n"
    #@status += "\n"
    #@status += "ENSURE ALL OF YOUR MACHINES ARE STOPPED <strong>BEFORE</strong> YOU WANT TO START SOME MACHINES!!!"
  end



  # show all machines that KCSD manages
  def showAll
    machine_array = getMachineArray()
    @info_array =[]
    machine_array.each do |instance|
      tmp_array = []
      tmp_array << instance.id
      tmp_array << instance.ip_address
      tmp_array << instance.private_ip_address
      tmp_array << instance.instance_type
      tmp_array << instance.image_id
      tmp_array << instance.status.to_s
      @info_array << tmp_array
    end
    return @info_array
  end




  # stop all machines that KCSD manages
  def stopAll
    machine_array = getMachineArray()
    @status = ""
    machine_array.each do |instance|
      # can only stop instances that are running
      if(instance.status != :running)
        @status += "Instance ID: <strong>#{instance.id}</strong> is now in state <strong>#{instance.status.to_s}</strong> and can not be stopped\n"
      else
        instance.stop
        @status += "Instance ID: <strong>#{instance.id}</strong> is now being stopped\n"
      end
    end
    return @status
  end






  def start

    # all machines that KCSD manages
    machine_array = getMachineArray()

    # get params
    number = params[:number_start].to_i
    flavor = ""
    if(params[:flavor_start] == "small_start")
      flavor = "m1.small"
    elsif(params[:flavor_start] == "medium_start")
      flavor = "m1.medium"
    else
      flavor = "m1.large"
    end


    # max is the available machines with a selected type can be invoked
    # for example:
    # 5 small instances, currently 2 are running
    # => max = 3
    max = 0
    # check if ok
    machine_array.each do |inst|
      if (inst.instance_type ==  flavor && inst.status != :running)
        max += 1
      end
    end

    @status = ""
    # enough machines
    if (number <= max)

      # get the machines with the selected flavor
      tmp_array = []
      machine_array.each do |inst|
        if(inst.instance_type == flavor)
          tmp_array << inst
        end
      end

      # start number machines
      delta = number - 1
      for i in 0..delta
        tmp_array[i].start
      end

      @status = "Start <strong>#{number}</strong> machines with flavor <strong>#{flavor}</strong>\n"
      @status += "\n"
      @status += "Click the <strong>back</strong> button below to come back dashboard\n"

    else
      @status += "KCSD has only <strong>#{max}</strong> machines with flavor <strong>#{flavor}</strong> available\n"
      @status += "\n"
      @status += "You need <strong>#{number}</strong> machines with flavor <strong>#{flavor}</strong>\n"
      @status += "\n"
      @status += "Maybe the some <strong>#{flavor}</strong> machines are running\n"
      @status += "\n"
      @status += "Or you have to create <strong>create</strong> more!"
      @status += "\n"
      @status += "Click the <strong>back</strong> button below to come back dashboard\n"
    end
  end






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





  # return the machines that KCSD manages in an array
  private
  def getMachineArray
    machine_array = []
    state = getState()
    key_pair_name = state["key_pair_name"]
    ec2 = init()
    ec2.instances.each do |instance|
      # show all the instances that KCSD manages
      if (instance.key_name == key_pair_name)
        # chef server is not including
        if (instance.id != state["chef_server_instance_id"])
          # the machine is not terminated
          if (instance.status != :terminated)
            machine_array << instance
          end
        end
      end
    end
    return machine_array
  end

end

