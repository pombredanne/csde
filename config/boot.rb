# load all needed gems by booting
#include Java

require 'rubygems'
require 'yaml'
require 'fog'
require 'yajl'
require 'parallel'
require 'psych'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
