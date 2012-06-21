# follow the DRY principle
# share code among controllers

module Helper
  
  # ============================================================ #
  # state.yml contains all related information for KCSD
  # KCSD stores data in files such as state.yml, not in database 
  # ============================================================ #
  
  # return state as a YAML object
  def get_state
    logger.debug "::: Loading state.yml..."
    state = YAML.load(File.open("#{Rails.root}/chef-repo/.chef/conf/state.yml"))
    state
  end



  # update state.yml
  # input as a YAML object
  def update_state state
    logger.debug "::: Updating state.yml..."
    File.open("#{Rails.root}/chef-repo/.chef/conf/state.yml","w") {|file| YAML.dump(state,file)}
  end



  # return knife_config as a YAML object
  def get_knife_config
    logger.debug "::: Loading knife.yml..."
    knife_config = YAML.load(File.open("#{Rails.root}/chef-repo/.chef/conf/knife.yml"))
    knife_config
  end



  # update knife.yml
  # input as a YAML object
  def update_knife_config knife_config
    logger.debug "::: Updating knife.yml..."
    File.open("#{Rails.root}/chef-repo/.chef/conf/knife.yml","w") {|file| YAML.dump(knife_config,file)}
  end



  # ============================================================ #
  # EC2 
  # ============================================================ #
  
  # get AWS credentials from state.yml
  # and create an EC2 object
  # KCSD uses this object to send/receive API requests/responses to EC2
  def create_ec2
    state = get_state
    logger.debug "::: Creating an EC2 object..."
    
    # aws-sdk way
    # ec2 = AWS::EC2.new(
      # :access_key_id => state['aws_access_key_id'],
      # :secret_access_key => state['aws_secret_access_key']
    # )
    
    # fog way
    ec2 = Fog::Compute.new(
      provider: 'AWS',
      aws_access_key_id: state['aws_access_key_id'],
      aws_secret_access_key: state['aws_secret_access_key'],
      region: 'us-east-1' # TODO, region is now hard coded
    )
    ec2
  end
  
  # check if sshd is ready in the remote machine
  # code reused from knife-ec2 plugin
  # https://github.com/opscode/knife-ec2/blob/master/lib/chef/knife/ec2_server_create.rb
  def tcp_test_ssh hostname
    tcp_socket = TCPSocket.new(hostname, 22)
    readable = IO.select([tcp_socket], nil, nil, 5)
    if readable
      logger.debug("::: sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
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
end