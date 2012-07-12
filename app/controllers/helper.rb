# follow the DRY principle
# share code among controllers

module Helper
  
  # ============================================================ #
  # state.yml contains all related information for KCSD
  # KCSDB stores data in files such as state.yml, not in database 
  # ============================================================ #
  
  # return state as a YAML object
  def get_state
    logger.debug "::: Loading state.yml..."
    state = YAML.load(File.open("#{Rails.root}/chef-repo/.chef/conf/state.yml"))
    logger.debug "::: Loading state.yml... [OK]"
    state
  end

  # update state.yml
  # input as a YAML object
  def update_state state
    logger.debug "::: Updating state.yml..."
    File.open("#{Rails.root}/chef-repo/.chef/conf/state.yml","w") {|file| YAML.dump(state,file)}
    logger.debug "::: Updating state.yml... [OK]"
  end

  # ============================================================ #
  # EC2 
  # ============================================================ #
  
  # get AWS credentials from state.yml
  # and create an EC2 object
  # KCSDB uses this object to send/receive API requests/responses to EC2
  # TODO: Garbage Collector in Ruby??
  def create_ec2
    state = get_state

    logger.debug "::: Creating an EC2 object..."
    ec2 = Fog::Compute.new(
      provider: 'AWS',
      aws_access_key_id: state['aws_access_key_id'],
      aws_secret_access_key: state['aws_secret_access_key'],
      region: state['region']
    )
    logger.debug "::: Creating an EC2 object... [OK]"
    ec2
  end
  
  # check if sshd is ready in the remote machine
  # code reused from knife-ec2 plugin
  # https://github.com/opscode/knife-ec2/blob/master/lib/chef/knife/ec2_server_create.rb
  def tcp_test_ssh hostname
    logger.debug "::: Checking sshd in #{hostname}, please wait..."
    tcp_socket = TCPSocket.new(hostname, 22)
    readable = IO.select([tcp_socket], nil, nil, 5)
    if readable
      logger.debug "::: Checking sshd in #{hostname}, please wait... [OK]"
    yield
    true
    else
    false
    end
  rescue SocketError
    sleep 2
    false
  rescue Errno::ETIMEDOUT
    false
  rescue Errno::EPERM
    false
  rescue Errno::ECONNREFUSED
    sleep 2
    false
    # This happens on EC2 quite often
  rescue Errno::EHOSTUNREACH
    sleep 2
    false
    # This happens on EC2 sometimes
  rescue Errno::ENETUNREACH
    sleep 2
    false
  ensure
    tcp_socket && tcp_socket.close
  end
  
  #capture private IPs of all selected running machines in EC2
  def capture_private_ips_of_running_machines
    logger.debug "::: Capturing private IPs of running machines..."

    # machines that KCSDB manages
    machine_array = get_machine_array
    
    #contain all running machines
    tmp_private_ips_of_running_machines = []

    #iterate all instances in EC2 environment
    #and get only the running instances
    #and add the private IPs of them to private_ips_of_running_instances array
    machine_array.each do |machine|
      if machine.state.to_s == "running"
        tmp_private_ips_of_running_machines << machine.private_ip_address
      end
    end

    #write to a temp file
    File.open("#{Rails.root}/chef-repo/.chef/capistrano-kcsd/n_ips.txt","w") do |file|
      tmp_private_ips_of_running_machines.each do |ip|
        file << ip << "\n"
      end
    end
  end

  # capture private IP of KCSDB server and save it into kcsdb_private_ip.txt
  def capture_private_ip_of_kcsdb_server
    logger.debug "::: Capturing the private IP of KCSDB Server..."
    system "curl http://169.254.169.254/latest/meta-data/local-ipv4 > #{Rails.root}/chef-repo/.chef/tmp/kcsdb_private_ip.txt"
  end

  #capture public IP of KCSDB server and save it into kcsdb_public_ip.txt
  def capture_public_ip_of_kcsdb_server  
    logger.debug "::: Capturing the public IP of KCSDB Server..."
    system "curl http://169.254.169.254/latest/meta-data/public-ipv4 > #{Rails.root}/chef-repo/.chef/tmp/kcsdb_public_ip.txt"
  end

  # update knife.rb depends on the KCSDB Server's IP  
  def update_knife_rb
    capture_public_ip_of_kcsdb_server
    
    kcsdb_public_ip_address = ""
    File.open("#{Rails.root}/chef-repo/.chef/tmp/kcsdb_public_ip.txt","r").each do |line|
      kcsdb_public_ip_address = line.to_s.strip
    end
    
    logger.debug "::: Updating knife.rb..."
    File.open("#{Rails.root}/chef-repo/.chef/conf/knife.rb",'w') do |file|
      file << "chef_server_url \'http://#{kcsdb_public_ip_address}:4000\'" << "\n"
      file << "node_name \'chef-webui\'" << "\n"
      file << "client_key \'/etc/chef/webui.pem\'" << "\n"
      file << "validation_client_name \'chef-validator\'" << "\n"
      file << "validation_key \'/etc/chef/validation.pem\'" << "\n"
      file << "cookbook_path \'#{Rails.root}/chef-repo/cookbooks\'"   
    end
    logger.debug "::: Updating knife.rb... [OK]"
  end

=begin  
  # return the machines that KCSDB manages in an array
  def get_machine_array
    logger.debug "::: Getting all machines that KCSDB manages..."
    machine_array = []
    ec2 = create_ec2
    state = get_state
    key_pair_name = state['key_pair_name']
    # chef_server_id = state['chef_server_id']
    
    ec2.servers.each do |server|
      # show all the instances that KCSD manages
      if server.key_name == key_pair_name
        # chef server is not including
        # if server.id != chef_server_id
          # the machine is not terminated
          if server.state.to_s != "terminated"
            machine_array << server
          end
        # end
      end
    end
    machine_array
  end
=end
end