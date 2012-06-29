require 'helper'
class ChefServerController < ApplicationController
  include Helper

  # go to Chef Server WebUI
  # which is running on the same machine as KCSDB Server
  def go_to
    capture_public_ip_of_kcsdb_server
    
    kcsdb_public_ip = ""
    File.open("#{Rails.root}/chef-repo/.chef/tmp/kcsdb_public_ip.txt","r").each do |line|
      kcsdb_public_ip = line.to_s.strip    
    end    
    
    redirect_to "http://#{kcsdb_public_ip}:4040"
  end
  
  # set up a fresh Chef Server
  # DEPRECATED
  def setup
    # INITIALIZE
    beginning = Time.now
    @status = ""
    ec2 = create_ec2
    state = get_state
    key_pair_name = state['key_pair_name']
    security_group_name = state['security_group_name']
    chef_server_ami = state['chef_server_ami']
    chef_server_flavor = state['chef_server_flavor']
    chef_server_ssh_user = state['chef_server_ssh_user']
    kcsdb_sudo_password = state['kcsdb_sudo_password']

    logger.debug "============================"
    logger.debug "Setting up a new Chef Server"
    logger.debug "============================"

    logger.debug "====================="
    logger.debug "Checking the key pair"
    logger.debug "====================="

    private_key_path = File.expand_path "#{Rails.root}/chef-repo/.chef/pem/#{key_pair_name}.pem"    
    
    # the public key in EC2 with given name and the private key in KCSD Server have to exist
    if  (File.exist? private_key_path) && (! ec2.key_pairs.get(key_pair_name).nil?)
      logger.debug "::: The private key #{key_pair_name}.pem in KCSDB Web Server: [OK]"
      logger.debug "::: The public key #{key_pair_name} in AWS EC2: [OK]"
    else
      logger.debug "::: Something wrong with the key pair..."
      logger.debug "::: That means, at least one of two following problems happens:"
      logger.debug "::: 1. The private key does NOT exist in KCSDB Web Server"
      logger.debug "::: 2. The public key does NOT exist in AWS EC2"
      if File.exist? private_key_path
        logger.debug "::: Deleting the private key in KCSDB Server..."
        File.delete private_key_path
        logger.debug "::: Deleting the private key in KCSDB Server... [OK]"
      end
      if ! ec2.key_pairs.get(key_pair_name).nil?
        logger.debug "::: Deleting the public key in AWS EC2..."
        ec2.delete_key_pair key_pair_name
        logger.debug "::: Deleting the public key in AWS EC2... [OK]"
      end

      logger.debug "::: Creating a new key pair..."
      key_pair = ec2.create_key_pair key_pair_name
      logger.debug "::: Creating a new key pair... [OK]"

      logger.debug "::: Saving #{key_pair_name}.pem..."
      private_key = key_pair.body['keyMaterial']
      File.open(private_key_path,'w') {|file| file << private_key}
      logger.debug "::: Saving #{key_pair_name}.pem... [OK]"

      # only user can read/write
      logger.debug "::: Setting mode 600 for the #{key_pair_name}.pem..."
      File.chmod(0600,private_key_path)
      logger.debug "::: Setting mode 600 for the #{key_pair_name}.pem... [OK]"
      
      logger.debug "::: The private key #{key_pair_name}.pem in KCSDB Web Server: [OK]"
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
      logger.debug "::: Creating a new security group #{security_group_name} in AWS EC2... [OK]"
      
      logger.debug "::: The security group #{security_group_name} in AWS EC2: [OK]"
    end
    
    logger.debug "==================================="
    logger.debug "Launchning a new machine in AWS EC2"
    logger.debug "==================================="
    
    logger.debug "::: Now, launching a new machine with following configurations..."
    logger.debug "::: AMI: #{chef_server_ami}"
    logger.debug "::: Flavor: #{chef_server_flavor}"
    logger.debug "::: SSH User: #{chef_server_ssh_user}"
    logger.debug "::: Key Pair: #{key_pair_name}"
    logger.debug "::: Security Group: #{security_group_name}"
    chef_server_def = {
      image_id: chef_server_ami,
      flavor_id: chef_server_flavor,
      key_name: key_pair_name,
      groups: security_group_name
    }
    chef_server = ec2.servers.create chef_server_def
    logger.debug "::: Adding tag KCSDB Chef Server..."
    ec2.tags.create :key => "Name", :value => "KCSDB Chef Server", :resource_id => chef_server.id

    logger.debug "::: Waiting for machine: #{chef_server.id}..."
    chef_server.wait_for { print "."; ready? }
    puts "\n"
    logger.debug "::: Waiting for machine: #{chef_server.id}... [OK]"

    logger.debug "::: Allocating an elastic IP from AWS EC2..."
    elastic_address = ec2.allocate_address
    elastic_ip = elastic_address.body['publicIp']
    logger.debug "::: Allocating an elastic IP from AWS EC2... [OK]"

    logger.debug "::: Assinging the newly allocated elastic IP: #{elastic_ip} to machine: #{chef_server.id}..."    
    ec2.associate_address(chef_server.id, elastic_ip)
    logger.debug "::: Assinging the newly allocated elastic IP: #{elastic_ip} to machine: #{chef_server.id}... [OK]"
    
    print "." until tcp_test_ssh(elastic_ip) { sleep 1 }

    logger.debug "===================================================="
    logger.debug "Installing Chef Server in machine: #{chef_server.id}"
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

    logger.debug "::: Uploading a bootstrap script to machine: #{chef_server.id}..."
    system "scp -i #{private_key_path} #{Rails.root}/chef-repo/.chef/sh/* #{chef_server_ssh_user}@#{elastic_ip}:/home/#{chef_server_ssh_user}"
    logger.debug "::: Uploading a bootstrap script to machine: #{chef_server.id}... [OK]"

    logger.debug "::: Executing the bootstrap script..."
    system "ssh -i #{private_key_path} #{chef_server_ssh_user}@#{elastic_ip} 'sudo bash bootstrap.sh'"
    logger.debug "::: Executing the bootstrap script... [OK]"
    
    logger.debug "::: Downloading webui.pem and validation.pem..."
    system "scp -i #{private_key_path} #{chef_server_ssh_user}@#{elastic_ip}:/home/#{chef_server_ssh_user}/.chef/*pem #{Rails.root}/chef-repo/.chef/pem"
    logger.debug "::: Downloading webui.pem and validation.pem... [OK]"

    logger.debug "======================================="
    logger.debug "Updating configurations in KCSDB Server"
    logger.debug "======================================="
    
    state['chef_server_state'] = 'setup'
    state['chef_server_id'] = chef_server.id
    state['chef_server_elastic_ip'] = elastic_ip
    state['chef_client_identity_file'] = "#{Rails.root}/chef-repo/.chef/pem/#{key_pair_name}.pem"
    state['chef_client_template_file'] = "#{Rails.root}/chef-repo/bootstrap/ubuntu12.04-gems.erb"
    update_state state

    # TODO
    # KCSD Server uses P2P protocol to distribute binaries code among the machines
    # And they must exist in the same region that KCSD exists
    # Now only us-east-1    
    logger.debug "::: Updating knife.rb..."
    File.open("#{Rails.root}/chef-repo/.chef/conf/knife.rb",'w') do |file|
      file << "chef_server_url \'http://#{elastic_ip}:4000\'" << "\n"
      file << "node_name \'chef-webui\'" << "\n"
      file << "client_key \'#{Rails.root}/chef-repo/.chef/pem/webui.pem\'" << "\n"
      file << "validation_client_name \'chef-validator\'" << "\n"
      file << "validation_key \'#{Rails.root}/chef-repo/.chef/pem/validation.pem\'" << "\n"
      file << "cookbook_path \'#{Rails.root}/chef-repo/cookbooks\'"   
    end
    logger.debug "::: Updating knife.rb... [OK]"
    
    logger.debug "::: Uploading all roles to Chef Server..."
    knife_role_string = ""
    knife_role_string << "knife role "
    knife_role_string << "--config #{Rails.root}/chef-repo/.chef/conf/knife.rb "
    knife_role_string << "from file #{Rails.root}/chef-repo/roles/*rb "
    system knife_role_string
    logger.debug "::: Uploading all roles to Chef Server... [OK]"

    logger.debug "::: Uploading all cookbooks to Chef Server..."
    knife_cookbook_upload_string = ""
    # knife_cookbook_upload_string << "echo #{kcsdb_sudo_password} | rvmsudo -S knife cookbook upload " #TODO: ruby installed via rvm
    knife_cookbook_upload_string << "rvmsudo knife cookbook upload " #TODO: ruby installed via rvm
    knife_cookbook_upload_string << "--config #{Rails.root}/chef-repo/.chef/conf/knife.rb "
    knife_cookbook_upload_string << "--all "
    system knife_cookbook_upload_string
    logger.debug "::: Uploading all cookbooks to Chef Server... [OK]"
    
    @status << "Thank you for waiting :)\n\n"
    @status << "Your Chef Server is already <strong>set up</strong>\n\n"
    @status << "Please <strong>refresh</strong> the page\n\n"
    @status << "You can go the Chef Server by clicking <strong>Go to Chef Server</strong>"
    
    logger.debug "::: The installation of a new fresh Chef Server takes #{Time.now - beginning} seconds"
  end

  # check the chef server's state
  # DEPRECATED
  def check
    # initialize
    ec2 = create_ec2
    state = get_state
    chef_server_id = state['chef_server_id']
    @status = ec2.servers.get(chef_server_id).state.to_s 
    @status
  end

  # start chef server
  # DEPRECATED
  def start
    # initialize
    ec2 = create_ec2
    state = get_state
    chef_server_id = state['chef_server_id']
    chef_server_elastic_ip = state['chef_server_elastic_ip']
    chef_server_ssh_user = state['chef_server_ssh_user']
    chef_server_identity_file = state['chef_client_identity_file']
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

      logger.debug "::: Waiting for Chef Server: #{chef_server_id}..."
      chef_server.wait_for { print "."; ready? }
      puts "\n"
      logger.debug "::: Waiting for Chef Server: #{chef_server_id}... [OK]"

      logger.debug "::: Assinging the elastic IP: #{chef_server_elastic_ip} to Chef Server: #{chef_server_id}..."    
      ec2.associate_address(chef_server_id, chef_server_elastic_ip)
      logger.debug "::: Assinging the elastic IP: #{chef_server_elastic_ip} to Chef Server: #{chef_server_id}... [OK]"
      
      print "." until tcp_test_ssh(chef_server_elastic_ip) { sleep 1 }
      
      logger.debug "::: Executing start script in Chef Server..."
      system "ssh -i #{chef_server_identity_file} #{chef_server_ssh_user}@#{chef_server_elastic_ip} 'sudo bash start_chef.sh'"
      logger.debug "::: Executing start script in Chef Server... [OK]"
      
      logger.debug "::: Chef Server is now running..."
      logger.debug "::: Please wait a while to go to Chef Server WebUI"
      @status << "Chef Server is now <strong>running</strong>...\n\n"
      @status << "Please wait a while to go to Chef Server Web UI by clicking <strong>Go to Chef Server</strong>"
    end
  end

  # stop chef server
  # DEPRECATED
  def stop
    # initialize
    ec2 = create_ec2
    state = get_state
    chef_server_id = state['chef_server_id']
    chef_server_elastic_ip = state['chef_server_elastic_ip']
    chef_server_ssh_user = state['chef_server_ssh_user']
    chef_server_identity_file = state['chef_client_identity_file']
    @status = ""

    # get the chef server
    chef_server = ec2.servers.get chef_server_id

    if chef_server.state.to_s != "running"
      logger.debug "::: Chef Server is now #{chef_server.state.to_s} and not in the state that can be stopped."
      logger.debug "::: Please try again later!"
      @status << "Chef Server now is <strong>#{chef_server.state.to_s}</strong> and not in the state that can be stopped. Please try again later"
    else
      logger.debug "::: Executing stop script in Chef Server..."
      system "ssh -i #{chef_server_identity_file} #{chef_server_ssh_user}@#{chef_server_elastic_ip} 'sudo bash stop_chef.sh'"
      logger.debug "::: Executing stop script in Chef Server... [OK]"

      logger.debug "::: Stopping Chef Server..."
      chef_server.stop

      @status << "Chef Server is now <strong>stopped</strong>!"
    end
  end
end
