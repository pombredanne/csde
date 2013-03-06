# follow the DRY principle
# share code among controllers

require "forwardable"

module Helper

  # Create Fob Object Facade
  # create a fog object in order to send/receive API requests/responses from/to cloud provider
  # supported providers: aws | rackspace
  # regions are corresponding to the provider: e.g. us-east-1 for aws
  # services are compute | storage
  def create_fog_object provider, region, service
    fog_object = nil
    state = get_state
    if provider == 'aws'
      if service == 'compute' then fog_object = create_fog_object_ec2 state, region end
      if service == 'storage' then fog_object = create_fog_object_s3 state, region end 
    elsif provider == 'rackspace'
      fog_object = create_fog_object_rackspace state, region
    else
      logger.debug "Provider: #{provider} is not supported...!"  
    end
    fog_object
  end
  
  # Create Fog Object EC2
  private
  def create_fog_object_ec2 state, region
    # standard region
    if region.nil?
      region = 'us-east-1'   
    end
    
    ec2 = Fog::Compute.new(
      provider: 'AWS',
      aws_access_key_id: state['aws_access_key_id'],
      aws_secret_access_key: state['aws_secret_access_key'],
      region: region
    )
    ec2
  end
  
  # Create Fog Object S3
  private
  def create_fog_object_s3 state, region
    # standard region
    if region.nil?
      region = 'us-east-1'   
    end
    
    s3 = Fog::Storage.new(
      provider: 'AWS',
      aws_access_key_id: state['aws_access_key_id'],
      aws_secret_access_key: state['aws_secret_access_key'],
      region: region
    )
    s3
  end
  
  
  # Create Fog Object Rackspace
  # TODO: each region in Rackspace is assigned a different account
  private
  def create_fog_object_rackspace state, region
    rackspace = Fog::Compute.new(
      provider: 'Rackspace',
      rackspace_api_key: state['rackspace_api_key'],
      rackspace_username: state['rackspace_username'],
    )
    rackspace
  end

  # ============================================================ #
  # state.yml contains all related information for KCSD
  # KCSDB stores data in files such as state.yml, not in database 
  # ============================================================ #
  
  # return state as a YAML object
  def get_state
    state = YAML.load(File.open("#{Rails.root}/chef-repo/.chef/conf/state.yml"))
    state
  end

  # update state.yml
  # input as a YAML object
  def update_state state
    File.open("#{Rails.root}/chef-repo/.chef/conf/state.yml","w") {|file| YAML.dump(state,file)}
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

  # capture private IP of KCSDB server and save it into kcsdb_private_ip.txt
  def capture_private_ip_of_csde_server
    logger.debug "::: Capturing the private IP of CSDE Server..."
    system "curl --location http://169.254.169.254/latest/meta-data/local-ipv4 --silent --output #{Rails.root}/chef-repo/.chef/tmp/csde_private_ip.txt"
  end

  #capture public IP of KCSDB server and save it into kcsdb_public_ip.txt
  def capture_public_ip_of_csde_server
    state = get_state
    os = state['os']
    logger.debug "::: Capturing the public IP of CSDE Server..."
    if os == 'ubuntu'
      system "curl --location http://169.254.169.254/latest/meta-data/public-ipv4 --silent --output #{Rails.root}/chef-repo/.chef/tmp/csde_public_ip.txt"
    else
      system "(ifconfig eth0 | grep 'inet ' | awk -F: '{print $2}' | awk '{print $1}') > #{Rails.root}/chef-repo/.chef/tmp/csde_public_ip.txt"       
    end  
  end

  # update knife.rb depends on the CSDE Server's IP  
  def update_knife_rb
    capture_public_ip_of_csde_server
    
    csde_public_ip_address = ""
    File.open("#{Rails.root}/chef-repo/.chef/tmp/csde_public_ip.txt","r").each do |line|
      csde_public_ip_address = line.to_s.strip
      logger.debug "CSDE IP: #{csde_public_ip_address}"
    end
    
    logger.debug "::: Updating knife.rb..."
    File.open("#{Rails.root}/chef-repo/.chef/conf/knife.rb",'w') do |file|
      file << "chef_server_url \'http://#{csde_public_ip_address}:4000\'" << "\n"
      file << "node_name \'chef-webui\'" << "\n"
      file << "client_key \'/etc/chef/webui.pem\'" << "\n"
      file << "validation_client_name \'chef-validator\'" << "\n"
      file << "validation_key \'/etc/chef/validation.pem\'" << "\n"
      file << "cookbook_path \'#{Rails.root}/chef-repo/cookbooks\'"   
    end
  end
  
  # returns the private key path for the given region
  def get_private_key region
    state = get_state
    key_pair = state['key_pair_name']
    private_key_path = "#{Rails.root}/chef-repo/.chef/pem/#{key_pair}-#{region}.pem"
    private_key_path
  end
end