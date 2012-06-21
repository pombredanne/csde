require 'helper'
class ChefServerController < ApplicationController
  include Helper

  # set up a fresh Chef Server
  def setup
    # INITIALIZE
    beginning = Time.now
    @status = "" # for view
    state = get_state
    knife_config = get_knife_config
    ec2 = create_ec2
    key_pair_name = state['key_pair_name']
    security_group_name = state['security_group_name']
    chef_server_ami = state['chef_server_ami']
    chef_server_flavor = state['chef_serve_flavor']

    logger.debug "============================"
    logger.debug "Setting up a new Chef Server"
    logger.debug "============================"

    logger.debug "====================="
    logger.debug "Checking the key pair"
    logger.debug "====================="

    private_key_path = File.expand_path "#{Rails.root}/chef-repo/.chef/pem/#{key_pair_name}.pem"    
    
    # the public key in EC2 with given name and the private key in KCSD Server have to exist
    if  (File.exist? private_key_path) && (! ec2.key_pairs.get(key_pair_name).nil?)
      logger.debug "::: The private key #{key_pair_name}.pem in KCSD Web Server: [OK]"
      logger.debug "::: The public key #{key_pair_name} in AWS EC2: [OK]"
    else
      logger.debug "::: Something wrong with the key pair..."
      logger.debug "::: That means, at least one of two following problems happens:"
      logger.debug "::: 1. The private key does NOT exist in KCSD Web Server"
      logger.debug "::: 2. The public key does NOT exist in AWS EC2"
      if File.exist? private_key_path
        logger.debug "::: Deleting the private key in KCSD Server..."
        File.delete private_key_path
      end
      if ! ec2.key_pairs.get(key_pair_name).nil?
        logger.debug "::: Deleting the public key in AWS EC2..."
        ec2.delete_key_pair key_pair_name
      end

      logger.debug "::: Creating a new key pair..."
      key_pair = ec2.create_key_pair key_pair_name

      logger.debug "::: Saving #{key_pair_name}.pem..."
      private_key = key_pair.body['keyMaterial']
      # write in file      
      File.open(private_key_path,'w') {|file| file << private_key}

      # only user can read/write
      logger.debug "::: Setting mode 600 for the #{key_pair_name}.pem..."
      File.chmod(0600,private_key_path)
      
      logger.debug "::: The private key #{key_pair_name}.pem in KCSD Web Server: [OK]"
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
      
      logger.debug "::: The security group #{security_group_name} in AWS EC2: [OK]"
    end
    
    logger.debug "=================================="
    logger.debug "Lauchning a new machine in AWS EC2"
    logger.debug "=================================="
    
    logger.debug "::: Now, lauching a new machine using AMI: #{chef_server_ami}..."
    chef_server_def = {
      image_id: chef_server_ami,
      flavor_id: chef_server_flavor,
      groups: security_group_name,
      key_name: key_pair_name
    }
    chef_server = ec2.servers.create(chef_server_def)
    chef_server_id = chef_server.id

    logger.debug "::: Waiting for machine: #{chef_server_id}..."
    chef_server.wait_for { print "."; ready? }
    puts "\n"
    logger.debug "::: The machine: #{chef_server_id} is ready [OK]"

    logger.debug "::: Allocating an elastic IP from AWS EC2..."
    elastic_address = ec2.allocate_address
    elastic_ip = elastic_address.body['publicIp']
    logger.debug "::: The new elastic IP: #{elastic_ip} is allocated in EC2 [OK]"

    logger.debug "::: Assinging the newly allocated elastic IP: #{elastic_ip} to machine: #{chef_server_id}..."    
    ec2.associate_address(chef_server_id, elastic_ip)
    logger.debug "::: The new elastic IP: #{elastic_ip} is assigned to machine: #{chef_server_id} [OK]"
    
    logger.debug "::: Checking if sshd in machine: #{chef_server_id} is ready, please wait..."
    print(".") until tcp_test_ssh(elastic_ip) {sleep 1}
    logger.debug "::: SSHD in machine: #{chef_server_id} with IP: #{elastic_ip} [OK]"

    logger.debug "===================================================="
    logger.debug "Installing Chef Server in machine: #{chef_server_id}"
    logger.debug "===================================================="

    # ssh stuff    
    if File.exist? "#{ENV['HOME']}/.ssh/known_hosts"
      logger.debug "::: Deleting old known hosts information in ~/.ssh/known_hosts"
      File.delete "#{ENV['HOME']}/.ssh/known_hosts"
    end
    system "mkdir -p $HOME/.ssh"
    File.open("#{ENV['HOME']}/.ssh/config",'w') do |file|
      file << "Host #{elastic_ip}" << "\n"
      file << "\t" << "StrictHostKeyChecking no" << "\n"
    end
    
    # the user to log in the machine
    # TODO
    # now, the user is hard coded, because KCSD use AMIs provided by Cannonical
    ec2_user = "ubuntu"
    logger.debug "::: User login to the machine: #{ec2_user}"

    logger.debug "::: Uploading bootstrap scripts to machine: #{chef_server_id}..."
    system "scp -i #{private_key_path} #{Rails.root}/chef-repo/.chef/sh/*.sh #{ec2_user}@#{elastic_ip}:/home/#{ec2_user}"
    logger.debug "::: Upload script [OK]"

    logger.debug "::: Executing bootstrap scripts..."
    system "ssh -i #{private_key_path} #{ec2_user}@#{elastic_ip} 'sudo bash bootstrap.sh'"
    logger.debug "::: Execute script [OK]"

    logger.debug "::: Downloading webui.pem and validation.pem..."
    system "scp -i #{private_key_path} #{ec2_user}@#{elastic_ip}:/home/#{ec2_user}/.chef/*pem #{Rails.root}/chef-repo/.chef/pem"
    logger.debug "::: Download pem files [OK]"

    logger.debug "======================================"
    logger.debug "Updating configurations in KCSD Server"
    logger.debug "======================================"
    
    state["chef_server_state"] = "setup"
    state["chef_server_url"] = "http://#{elastic_ip}:4000"
    state["chef_server_elastic_ip"] = "#{elastic_ip}"
    state["chef_server_id"] = "#{chef_server_id}"
    state["key_pair_name"] = "#{key_pair_name}"
    state["security_group_name"] = "#{security_group_name}"
    update_state state

    # TODO
    # KCSD Server uses P2P protocol to distribute binaries code among the machines
    # And they must exist in the same region that KCSD exists
    # Now only us-east-1
    knife_config["chef_server_url"] = "http://#{elastic_ip}:4000"
    knife_config["node_name"] = "chef-webui"
    knife_config["client_key"] = "#{Rails.root}/chef-repo/.chef/pem/webui.pem"
    knife_config["validation_client_name"] = "chef-validator"
    knife_config["validation_key"] = "#{Rails.root}/chef-repo/.chef/pem/validation.pem"
    knife_config["cookbook_path"] = "#{Rails.root}/chef-repo/cookbooks"
    knife_config['knife[:aws_ssh_key_id]'] = "#{key_pair_name}"
    knife_config['knife[:identify_file]'] = "#{Rails.root}/chef-repo/.chef/pem/#{key_pair_name}.pem"
    knife_config['knife[:ssh_user]'] = "#{ec2_user}"
    knife_config['knife[:security_groups]'] = "#{security_group_name}"
    update_knife_config knife_config

    @status += "Thank you for waiting :)\n\n"
    @status += "Your Chef Server is already <strong>set up</strong>\n\n"
    @status += "Please <strong>refresh</strong> the page\n\n"
    @status += "You can go the Chef Server by clicking <strong>Go to Chef Server</strong>"
    
    logger.debug "::: The installation of a new fresh Chef Server takes #{Time.now - beginning} seconds"
  end





  def check
    chef_server_instance = getChef()
    @status = chef_server_instance.status.to_s
    return @status
  end






  def start
    state = getState()
    stateKnife = getStateKnife()
    chef_server_instance = getChef()

    if(chef_server_instance.status != :stopped)
      @status = "Chef Server now is <strong>#{chef_server_instance.status}</strong> and not in the state that can be started. Please try again later!"
    else
      chef_server_instance.start

      # until chef server instance is NOT pending any more
      # than associate with the given elastic IP read from knife.rb
      puts "Please wait another moment, the Chef Server is now pending..."
      sleep 1 until chef_server_instance.status != :pending

      puts "Assigning elastic ip..."
      chef_server_instance.associate_elastic_ip(state["chef_server_elastic_ip"])
      sleep 10
      # until chef server instance has an elastic ip
      # than invoke task rabbitmq to add a new "chef" user in vhost "/chef" in RabbitMQ in Chef Server
      #sleep 1 until chef_server_instance.elastic_ip.nil? == false

      # preparation
      identity_file = stateKnife['knife[:identify_file]']
      ssh_user = stateKnife['knife[:ssh_user]']
      elastic_ip = state['chef_server_elastic_ip']

      #delete old stuff of ssh
      system "if [ -e $HOME/.ssh/known_hosts ]; then rm $HOME/.ssh/known_hosts; fi"

      # ping
      system "while ! ssh -o StrictHostKeyChecking=no -i #{identity_file} #{ssh_user}@#{elastic_ip} true; do echo -n .; sleep .5; done"

      # adding new user "chef" in vhost "/chef" to Chef Server
      # run the script
      system "ssh -i #{identity_file} #{ssh_user}@#{elastic_ip} 'sudo bash start_chef_conf.sh'"

      @status = "Chef Server is now <strong>running</strong>...\n"
      @status += "\n"
      @status += "Please wait a while to go to Chef Server Web UI by clicking <strong>Go to Chef Server</strong>"

    end
  end






  def stop
    state = getState()
    stateKnife = getStateKnife()
    chef_server_instance = getChef()

    if(chef_server_instance.status != :running)
      @status = "Chef Server now is <strong>#{chef_server_instance.status.to_s}</strong> and not in the state that can be stopped. Please try again later"
    else

      # preparation
      identity_file = stateKnife['knife[:identify_file]']
      ssh_user = stateKnife['knife[:ssh_user]']
      elastic_ip = state['chef_server_elastic_ip']

      #delete old stuff of ssh
      system "if [ -e $HOME/.ssh/known_hosts ]; then rm $HOME/.ssh/known_hosts; fi"

      # ping
      system "while ! ssh -o StrictHostKeyChecking=no -i #{identity_file} #{ssh_user}@#{elastic_ip} true; do echo -n .; sleep .5; done"

      # run the script
      system "ssh -i #{identity_file} #{ssh_user}@#{elastic_ip} 'sudo bash stop_chef_conf.sh'"

      chef_server_instance.stop()
      sleep(1) until chef_server_instance.status != :stopping

      @status = "Chef Server is now <strong>stopped</strong>!"
    end
  end





  def go_to
    state = get_state
    redirect_to "http://#{state['chef_server_elastic_ip']}:4040"
  end






  private
  def getChef
    state = getState()
    ec2 = init()

    chef_server_instance_id = state["chef_server_instance_id"]
    chef_server_instance = ec2.instances[chef_server_instance_id]

    return chef_server_instance
  end
end
