require "State"
require "Ec2"
class DeploymentController < ApplicationController

  include State
  include Ec2



  def opscenter
    # OpsCenter supports only Cassandra 1.0.x
    editCapfile("10")

    puts "::: INSTALLING OPSCENTER..."

    @status = ""

    # capture private IP of KCSD Server
    capturePrivateIPOfKCSDServer

    # capture public IP of KCSD Server
    capturePublicIPOfKCSDServer

    # get the public IP of KCSD Server from file
    @public_ip_of_KCSD = ""
    File.open("#{Rails.root}/chef-repo/.chef/capistrano-kcsd/kcsd_public_ip.txt","r").each {|line| @public_ip_of_KCSD << line}

    # capture private IPs of running machines
    capturePrivateIPsOfSelectedNodes

    capfile = "#{Rails.root}/chef-repo/.chef/capistrano-kcsd/Capfile"

    #START
    system "cap -f #{capfile} -T"
    system "cap -f #{capfile} kcsd:install_opscenter"
    system "cap -f #{capfile} kcsd:start_opscenter"

    @status += "OpsCenter is now <strong>ready</strong>\n"
    @status += "\n"

    return @status

  end




  def deploy
    cassandra_version = params[:cassandra_version]
    @status = cassandra_version

    puts "::: DEPLOY PRE DEFINED CASSANDRA VERSION #{cassandra_version}"

    @status = ""

    # capture private IP of KCSD Server
    capturePrivateIPOfKCSDServer

    # capture private IPs of running machines
    capturePrivateIPsOfSelectedNodes

    # edit Capfile
    editCapfile(cassandra_version)

    capfile = "#{Rails.root}/chef-repo/.chef/capistrano-kcsd/Capfile"


    #START
    system "cap -f #{capfile} -T"


    system "cap -f #{capfile} kcsd:prepare_distribution"
    system "cap -f #{capfile} kcsd:start_tracker"
    system "cap -f #{capfile} kcsd:get_source_files_for_the_seeder"
    system "cap -f #{capfile} kcsd:create_torrent_in_the_seeder"

    beginning = Time.now

    system "cap -f #{capfile} kcsd:start_seeding"
    system "cap -f #{capfile} kcsd:start_peering"
    system "cap -f #{capfile} kcsd:clean_temp_files"
    system "cap -f #{capfile} kcsd:stop_all"

    puts "Time elapsed for #{@number_of_running_machines} machines: #{Time.now - beginning} seconds"

	#TEST
	
    #system "cap -f #{capfile} kcsd:configure_cassandra"
    #system "cap -f #{capfile} kcsd:start_cassandra"

    #@status += "Cassandra cluster is now <strong>ready</strong>\n"
    @status += "Binaries code are already distributed!\n"

    return @status
  end







  def clean
    #invoke editCapfile with a dummy version
    #in order to create a Capfile
    editCapfile("10")

    puts "::: CLEANING UP..."

    @status = ""

    # capture private IP of KCSD Server
    capturePrivateIPOfKCSDServer

    # capture private IPs of running machines
    capturePrivateIPsOfSelectedNodes

    capfile = "#{Rails.root}/chef-repo/.chef/capistrano-kcsd/Capfile"


    #START
    system "cap -f #{capfile} kcsd:stop_opscenter"
    system "cap -f #{capfile} kcsd:stop_cassandra"
    system "cap -f #{capfile} kcsd:clean_everything"

    @status += "Everything from the last distribution is <strong>cleaned</strong>!"

    return @status
  end






  #capture private IPs of all selected running machines in EC2
  private
  def capturePrivateIPsOfSelectedNodes
    # machines that KCSD manages
    machine_array = getMachineArray()

    #contain all running instances
    tmp_private_ips_of_running_instances = []

    #iterate all instances in EC2 environment
    #and get only the running instances
    #and add the private IPs of them to private_ips_of_running_instances array
    machine_array.each do |instance|
      if(instance.status == :running)
        tmp_private_ips_of_running_instances << instance.private_ip_address
      end
    end

    #write to a temp file
    f = File.open("#{Rails.root}/chef-repo/.chef/capistrano-kcsd/n_ips.txt","w")
    line = ""
    tmp_private_ips_of_running_instances.each do |ip|
      line += ip
      line += "\n"
    end
    f.write(line)
    f.close()
  end




  # capture private IP of KCSD server
  #private
  #def capturePrivateIPOfKCSDServer
  #  # TODO: have to find another solution to capture the private IP of running KCSD Server
  #  # addr: 10 => private IP of AWS
  #  system "/sbin/ifconfig $1 | grep 'inet addr:10' | awk -F: '{print $2}' | awk '{print $1}' > #{Rails.root}/chef-repo/.chef/capistrano-kcsd/kcsd_ip.txt"
  #
  #  #system "/sbin/ifconfig $1 | grep 'inet addr:' | awk -F: '{print $2}' | awk '{print $1}' > #{Rails.root}/chef-repo/.chef/capistrano-kcsd/kcsd_ip.txt"
  #end


  #capture private IP of KCSD server
  private
  def capturePrivateIPOfKCSDServer
    system "curl http://169.254.169.254/latest/meta-data/local-ipv4 > #{Rails.root}/chef-repo/.chef/capistrano-kcsd/kcsd_ip.txt"
  end

  #capture public IP of KCSD server
  private
  def capturePublicIPOfKCSDServer
    system "curl http://169.254.169.254/latest/meta-data/public-ipv4 > #{Rails.root}/chef-repo/.chef/capistrano-kcsd/kcsd_public_ip.txt"
  end








  #edit Capfile for using Capistrano
  private
  def editCapfile(version)
    stateKnife = getStateKnife()

    user = stateKnife['knife[:ssh_user]']
    keys = stateKnife['knife[:identify_file]']


    cas_ver = ""
    cas_source = ""
    if(version=="7")
      cas_ver = "0.7.10"
      cas_source = 'http://archive.apache.org/dist/cassandra/0.7.10/apache-cassandra-0.7.10-bin.tar.gz'
    elsif(version=="8")
      cas_ver = "0.8.10"
      cas_source = 'http://archive.apache.org/dist/cassandra/0.8.10/apache-cassandra-0.8.10-bin.tar.gz'
    else
      cas_ver = "1.0.x"
      #cas_source = 'http://archive.apache.org/dist/cassandra/1.0.8/apache-cassandra-1.0.8-bin.tar.gz'
      
      #TEST
      cas_source = 'http://archive.apache.org/dist/cassandra/1.0.8/apache-cassandra-1.0.8-bin.tar.gz'
    end

    f_source = File.open("#{Rails.root}/chef-repo/.chef/capistrano-kcsd/Capfile_template","r")
    f_dest = File.open("#{Rails.root}/chef-repo/.chef/capistrano-kcsd/Capfile","w")

    str = ""
    f_source.each do |line|
      if (line.start_with?("set :cassandra_version, 'dummy'"))
        str += line.gsub("set :cassandra_version, 'dummy'","set :cassandra_version, \"#{cas_ver}\"")
        str += "\n"
      elsif (line.start_with?("set :source_files_path, 'dummy'"))
        str += line.gsub("set :source_files_path, 'dummy'","set :source_files_path, \"#{cas_source}\"")
        str += "\n"
      elsif (line.start_with?("set :user, 'dummy'"))
        str += line.gsub("set :user, 'dummy'","set :user, \"#{user}\"")
        str += "\n"
      elsif (line.start_with?("ssh_options[:keys] = 'dummy'"))
        str += line.gsub("ssh_options[:keys] = 'dummy'","ssh_options[:keys] = \"#{keys}\"")
        str += "\n"


      else
        str += line.to_s
        str += "\n"
      end
    end
    f_dest.write(str)
    f_source.close
    f_dest.close

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

    @number_of_running_machines = machine_array.size

    return machine_array
  end

end
