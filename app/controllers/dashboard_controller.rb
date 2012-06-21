require 'helper'
class DashboardController < ApplicationController
  include Helper

  def show
    # check if Chef Server is set up or not
    @state = get_state
    if(@state["chef_server_state"] == "not_setup")
      @status = ""
      @status += ":::::: Chef Server is <strong>not setup</strong> ::::::\n"
      @status += "\n"
      @status += "This is the first time you use KCSD, please click on tab <strong>About</strong> to get more information\n"
      @status += "\n"
      @status += "After reading, do as follows\n"
      @status += "\n"
      @status += "<em>First</em>, click on tab <strong>Configuration</strong>, input your <strong>AWS Credentials</strong>\n"
      @status += "\n"
      @status += "<em>Second</em>, click on tab <strong>Infrastructure</strong>, create a <strong>fresh Chef Server</strong>\n"
    else
      @status = ""
      @status += ":::::: Chef Server is now <strong>ready</strong> ::::::\n"
      @status += "\n"
      @status += "Click on tab <strong>Infrastructure</strong>, then <strong>Check | Start | Stop | Go to Chef Server</strong>\n"
      @status += "\n"
      @status += "Please ensure that all <strong>AWS credentials</strong> are correct!"
    end
  end


  # reset KCSD
  def reset
    # get all machines including Chef Server
    puts "Get all machines including Chef Server"
    all = getAll()

    puts "Iterating..."
    # iterate and terminate
    all.each do |machine|
      # machine has elastic IP => Chef Server => Release the elastic IP
      if(machine.has_elastic_ip?)
        puts "Deleting the elastic IP..."
        elastic_ip = machine.elastic_ip()
        elastic_ip.delete()
      end

      # terminate
      machine.terminate()
    end

    # update state.yml
    puts "Updating state.yml..."
    state = getState()
    state["chef_server_state"] = "not_setup"
    state["chef_server_url"] = "dummy"
    state["chef_server_elastic_ip"] = "dummy"
    state["chef_server_instance_id"] = "dummy"
    state["key_pair_name"] = "dummy"
    state["security_group"] = "dummy"
    state["aws_access_key_id"] = "dummy"
    state["aws_secret_access_key"] = "dummy"
    updateState(state)

    # update knife.yml
    puts "Updating knife.yml..."
    state = getStateKnife()
    state["chef_server_url"] = "dummy"
    state["node_name"] = "dummy"
    state["client_key"] = "dummy"
    state["validation_client_name"] = "dummy"
    state["validation_key"] = "dummy"
    state["cookbook_path"] = "dummy"
    state['knife[:aws_ssh_key_id]'] = "dummy"
    state['knife[:identify_file]'] = "dummy"
    state['knife[:ssh_user]'] = "dummy"
    state['knife[:security_groups]'] = "dummy"
    state['knife[:aws_access_key_id]'] = "dummy"
    state['knife[:aws_secret_access_key]'] = "dummy"
    updateStateKnife(state)

    # delete all private key
    puts "Deleting all pem files..."
    system "rm #{Rails.root}/chef-repo/.chef/pem/*"

    # delete opscenter if installed in KCSD Server
    system "if [ -e $HOME/opscenter ]; then rm -rf $HOME/opscenter; fi"

    # done, back to dashboard
    puts "Reset done [OK]"
    redirect_to "/"
  end




  # return the machines including Chef Server that KCSD manages in an array
  private
  def getAll
    machine_array = []
    state = getState()
    key_pair_name = state["key_pair_name"]
    ec2 = init()
    ec2.instances.each do |instance|
      # show all the instances that KCSD manages
      if (instance.key_name == key_pair_name)
        # the machine is not terminated
          if (instance.status != :terminated)
            machine_array << instance
          end
      end
    end
    return machine_array
  end

end
