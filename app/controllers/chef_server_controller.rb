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
    ec2_user = state['chef_server_ssh_user']

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
    knife_config['knife[:security_groups]'] = "#{security_group_name}"
    update_knife_config knife_config

    @status << "Thank you for waiting :)\n\n"
    @status << "Your Chef Server is already <strong>set up</strong>\n\n"
    @status << "Please <strong>refresh</strong> the page\n\n"
    @status << "You can go the Chef Server by clicking <strong>Go to Chef Server</strong>"
    
    logger.debug "::: The installation of a new fresh Chef Server takes #{Time.now - beginning} seconds"
  end

  # check the chef server's state
  def check
    chef_server = get_chef
    @status = chef_server.state.to_s
    @status
  end

  # start chef server
  def start
    # initialize
    ec2 = create_ec2
    state = get_state
    chef_server_id = state['chef_server_id']
    elastic_ip = state['chef_server_elastic_ip']
    ssh_user = state['chef_server_ssh_user']
    key_pair_name = state['key_pair_name']
    identity_file = File.expand_path "#{Rails.root}/chef-repo/.chef/pem/#{key_pair_name}.pem"
    @status = ""

    # get the chef server
    chef_server = ec2.servers.get chef_server_id

    if chef_server.state.to_s != "stopped"
      logger.debug "::: Chef Server is now #{chef_server.state.to_s} and not in the state that can be started."
      logger.debug "::: Please, try again later!"
      @status << "Chef Server now is <strong>#{chef_server.state.to_s}</strong> and not in the state that can be started. Please try again later!"
    else
      logger.debug "::: Starting Chef Server..."
      chef_server.start

      logger.debug "::: Waiting for Chef Server: #{chef_server.id}..."
      chef_server.wait_for { print "."; ready? }
      puts "\n"
      logger.debug "::: Chef Server: #{chef_server.id} is ready [OK]"

      logger.debug "::: Assinging the elastic IP: #{elastic_ip} to Chef Server: #{chef_server.id}..."    
      ec2.associate_address(chef_server.id, elastic_ip)
      logger.debug "::: The elastic IP: #{elastic_ip} is assigned to Chef Server: #{chef_server.id} [OK]"

      logger.debug "::: Checking if sshd in Chef Server: #{chef_server.id} is ready, please wait..."
      print "." until tcp_test_ssh(elastic_ip) { sleep 1 }
      logger.debug "::: SSHD in Chef Server: #{chef_server.id} with IP: #{elastic_ip} [OK]"
      
      logger.debug "::: Executing start script in Chef Server..."
      system "ssh -i #{identity_file} #{ssh_user}@#{elastic_ip} 'sudo bash start_chef.sh'"
      
      logger.debug "::: Chef Server is now running..."
      logger.debug "::: Please wait a while to go to Chef Server WebUI"
      @status << "Chef Server is now <strong>running</strong>...\n\n"
      @status << "Please wait a while to go to Chef Server Web UI by clicking <strong>Go to Chef Server</strong>"
    end
  end

  # stop chef server
  def stop
    # initialize
    ec2 = create_ec2
    state = get_state
    chef_server_id = state['chef_server_id']
    elastic_ip = state['chef_server_elastic_ip']
    ssh_user = state['chef_server_ssh_user']
    key_pair_name = state['key_pair_name']
    identity_file = File.expand_path "#{Rails.root}/chef-repo/.chef/pem/#{key_pair_name}.pem"
    @status = ""

    # get the chef server
    chef_server = ec2.servers.get chef_server_id

    if chef_server.state.to_s != "running"
      logger.debug "::: Chef Server is now #{chef_server.state.to_s} and not in the state that can be stopped."
      logger.debug "::: Please try again later!"
      @status << "Chef Server now is <strong>#{chef_server.state.to_s}</strong> and not in the state that can be stopped. Please try again later"
    else
      logger.debug "::: Executing stop script in Chef Server..."
      system "ssh -i #{identity_file} #{ssh_user}@#{elastic_ip} 'sudo bash stop_chef.sh'"

      logger.debug "::: Stopping Chef Server..."
      chef_server.stop

      @status << "Chef Server is now <strong>stopped</strong>!"
    end
  end

  # go to Chef Server WebUI
  def go_to
    state = get_state
    redirect_to "http://#{state['chef_server_elastic_ip']}:4040"
  end
end
