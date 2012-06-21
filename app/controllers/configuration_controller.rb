require 'helper'
class ConfigurationController < ApplicationController
  include Helper
  
  # update state.yml and knife.yml
  def edit_aws
    state = get_state
    state['aws_access_key_id'] = params[:aws_access_key_id]
    state['aws_secret_access_key'] = params[:aws_secret_access_key]
    state['key_pair_name'] = params[:key_pair_and_group]
    state['security_group_name'] = params[:key_pair_and_group]
    update_state state

    knife_config = get_knife_config
    knife_config['knife[:aws_access_key_id]'] = params[:aws_access_key_id]
    knife_config['knife[:aws_secret_access_key]'] = params[:aws_secret_access_key]
    update_knife_config knife_config
  end
end
