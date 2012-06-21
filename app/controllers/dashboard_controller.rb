require 'helper'
class DashboardController < ApplicationController
  include Helper

  # KCSDB starts from here
  def show
    # check if Chef Server is set up or not
    @state = get_state
    if(@state["chef_server_state"] == "not_setup")
      @status = ""
      @status << ":::::: Chef Server is <strong>not setup</strong> ::::::\n\n"
      @status << "This is the first time you use KCSD, please click on tab <strong>About</strong> to get more information\n\n"
      @status << "After reading, do as follows\n"
      @status << "<em>First</em>, click on tab <strong>Configuration</strong>, input your <strong>AWS Credentials</strong>\n\n"
      @status << "<em>Second</em>, click on tab <strong>Infrastructure</strong>, create a <strong>fresh Chef Server</strong>"
    else
      @status = ""
      @status += ":::::: Chef Server is now <strong>ready</strong> ::::::\n\n"
      @status += "Click on tab <strong>Infrastructure</strong>, then <strong>Check | Start | Stop | Go to Chef Server</strong>\n\n"
      @status += "Please ensure that all <strong>AWS credentials</strong> are correct!"
    end
  end

  # reset KCSDB
  def reset
    
    # initialize
    machine_array = []
    ec2 = create_ec2
    state = get_state
    knife_config = get_knife_config
    key_pair_name = state['key_pair_name']
    elastic_ip = state['chef_server_elastic_ip']
    
    logger.debug "::: Getting all machines including Chef Server..."
    ec2.servers.each do |server|
      # show all the instances that KCSD manages
      if server.key_name == key_pair_name
        # the machine is not terminated
        if server.state.to_s != "terminated"
          machine_array << server.id
        end
      end
    end

    logger.debug "::: Terminating all machines including Chef Server..."
    ec2.terminate_instances machine_array

    logger.debug "::: Releasing Chef Server's elastic IP..."
    ec2.release_address elastic_ip

    state["chef_server_state"] = "not_setup"
    state["chef_server_url"] = "dummy"
    state["chef_server_id"] = "dummy"
    state["chef_server_elastic_ip"] = "dummy"
    state["key_pair_name"] = "dummy"
    state["security_group_name"] = "dummy"
    state["aws_access_key_id"] = "dummy"
    state["aws_secret_access_key"] = "dummy"
    update_state state

    knife_config["chef_server_url"] = "dummy"
    knife_config["node_name"] = "dummy"
    knife_config["client_key"] = "dummy"
    knife_config["validation_client_name"] = "dummy"
    knife_config["validation_key"] = "dummy"
    knife_config["cookbook_path"] = "dummy"
    knife_config['knife[:aws_access_key_id]'] = "dummy"
    knife_config['knife[:aws_secret_access_key]'] = "dummy"
    knife_config['knife[:aws_ssh_key_id]'] = "dummy"
    knife_config['knife[:identify_file]'] = "dummy"
    knife_config['knife[:ssh_user]'] = "dummy"
    knife_config['knife[:security_groups]'] = "dummy"
    update_knife_config knife_config

    logger.debug "::: Deleting all pem files..."
    system "rm #{Rails.root}/chef-repo/.chef/pem/*pem"

    # delete opscenter if installed in KCSD Server
    logger.debug "::: Deleting OpsCenter in KCSD Server if exist..."
    system "if [ -e $HOME/opscenter ]; then rm -rf $HOME/opscenter; fi"

    logger.debug "Reset done [OK]"
    redirect_to "/"
  end
end
