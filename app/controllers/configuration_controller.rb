require 'helper'
class ConfigurationController < ApplicationController
  include Helper
  
  # update state.yml
  def edit_aws
    state = get_state
    state['aws_access_key_id'] = params[:aws_access_key_id]
    state['aws_secret_access_key'] = params[:aws_secret_access_key]
    state['key_pair_name'] = params[:key_pair_and_group]
    state['security_group_name'] = params[:key_pair_and_group]
    update_state state
  end
end
