require 'helper'
class DeploymentController < ApplicationController
  include Helper

  def opscenter
    # OpsCenter supports only Cassandra 1.0.x
    edit_capfile "10"

    logger.debug "::: Installing OpsCenter..."

    @status = ""

    # capture private IP of KCSD Server
    capture_private_ip_of_kcsdb_server

    # capture public IP of KCSD Server
    capture_public_ip_of_kcsdb_server

    # get the public IP of KCSD Server from file
    @public_ip_of_KCSD = ""
    File.open("#{Rails.root}/chef-repo/.chef/capistrano-kcsd/kcsdb_public_ip.txt","r").each {|line| @public_ip_of_KCSD << line}

    # capture private IPs of running machines
    capture_private_ips_of_running_machines

    capfile = "#{Rails.root}/chef-repo/.chef/capistrano-kcsd/Capfile"

    #START
    system "cap -f #{capfile} -T"
    system "cap -f #{capfile} kcsd:install_opscenter"
    system "cap -f #{capfile} kcsd:start_opscenter"

    @status << "OpsCenter is now <strong>ready</strong>\n\n"
  end

  # deploy a Cassandra cluster
  def deploy
    cassandra_version = params[:cassandra_version]
    @status = "Cassandra version: #{cassandra_version} is selected\n\n"

    logger.debug "::: Deploying pre defined Cassandra Version: #{cassandra_version}..."

    # capture private IP of KCSD Server
    capture_private_ip_of_kcsdb_server

    # capture private IPs of running machines
    capture_private_ips_of_running_machines

    # edit Capfile
    edit_capfile cassandra_version

    capfile = "#{Rails.root}/chef-repo/.chef/capistrano-kcsd/Capfile"

    #START
    system "cap -f #{capfile} -T"

    system "cap -f #{capfile} kcsd:prepare_distribution"
    system "cap -f #{capfile} kcsd:start_tracker"
    system "cap -f #{capfile} kcsd:get_source_files_for_the_seeder"
    system "cap -f #{capfile} kcsd:create_torrent_in_the_seeder"

    system "cap -f #{capfile} kcsd:start_seeding"
    system "cap -f #{capfile} kcsd:start_peering"
    system "cap -f #{capfile} kcsd:clean_temp_files"
    system "cap -f #{capfile} kcsd:stop_all"

    system "cap -f #{capfile} kcsd:configure_cassandra"
    system "cap -f #{capfile} kcsd:start_cassandra"

    @status += "Cassandra cluster is now <strong>ready</strong>\n"
  end

  def clean
    #invoke editCapfile with a dummy version
    #in order to create a Capfile
    edit_capfile "10"

    logger.debug "::: CLEANING UP..."

    # capture private IP of KCSDB Server
    capture_private_ip_of_kcsdb_server

    # capture private IPs of running machines
    capture_private_ips_of_running_machines

    capfile = "#{Rails.root}/chef-repo/.chef/capistrano-kcsd/Capfile"

    #START
    system "cap -f #{capfile} kcsd:stop_opscenter"
    system "cap -f #{capfile} kcsd:stop_cassandra"
    system "cap -f #{capfile} kcsd:clean_everything"

    @status = "Everything from the last distribution is <strong>cleaned</strong>!"
  end

  #edit Capfile for using Capistrano
  private
  def edit_capfile version
    logger.debug "::: Editing Capfile for using Capistrano..."
    
    state = get_state
    ssh_user = state['chef_client_ssh_user']
    identity_file = state['chef_client_identity_file']

    cassandra_version = ""
    cassandra_source = ""
    if version == "7"
      cassandra_version = "0.7.10"
      cassandra_source = 'http://archive.apache.org/dist/cassandra/0.7.10/apache-cassandra-0.7.10-bin.tar.gz'
    elsif version == "8"
      cassandra_version = "0.8.10"
      cassandra_source = 'http://archive.apache.org/dist/cassandra/0.8.10/apache-cassandra-0.8.10-bin.tar.gz'
    else
      cassandra_version = "1.0.x"
      cassandra_source = 'http://archive.apache.org/dist/cassandra/1.1.1/apache-cassandra-1.1.1-bin.tar.gz'
    end

    f_source = File.open("#{Rails.root}/chef-repo/.chef/capistrano-kcsd/Capfile_template","r")
    f_dest = File.open("#{Rails.root}/chef-repo/.chef/capistrano-kcsd/Capfile","w")
    str = ""
    f_source.each do |line|
      if line.start_with? "set :cassandra_version, 'dummy'"
        str << line.gsub("set :cassandra_version, 'dummy'","set :cassandra_version, \"#{cassandra_version}\"")
        str << "\n"
      elsif line.start_with? "set :source_files_path, 'dummy'"
        str << line.gsub("set :source_files_path, 'dummy'","set :source_files_path, \"#{cassandra_source}\"")
        str << "\n"
      elsif line.start_with? "set :user, 'dummy'"
        str << line.gsub("set :user, 'dummy'","set :user, \"#{ssh_user}\"")
        str << "\n"
      elsif line.start_with? "ssh_options[:keys] = 'dummy'"
        str << line.gsub("ssh_options[:keys] = 'dummy'","ssh_options[:keys] = \"#{identity_file}\"")
        str << "\n"
      else
        str << line.to_s
        str << "\n"
      end
    end
    f_dest.write str
    f_source.close
    f_dest.close
  end
end
