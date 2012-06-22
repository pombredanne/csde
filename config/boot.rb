# load all needed gems by booting

require 'rubygems'
require 'yaml'
require 'fog'
require 'chef'

# parallel knife bootstrap
# require 'chef/knife/bootstrap'
# require 'chef/knife/ssh'
# require 'chef/knife/core/bootstrap_context'
# require 'chef/json_compat'
# require 'chef/exceptions'
# require 'chef/search/query'
# require 'chef/mixin/shell_out'
# require 'tempfile'
# require 'highline'
# require 'net/ssh'
# require 'net/ssh/multi'
# require 'readline'
# require 'mixlib/shellout'


# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
