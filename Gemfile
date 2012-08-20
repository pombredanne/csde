# @author: Hoang Anh Le | me[at]lehoanganh[dot]de
#

source 'https://rubygems.org'

# ======================================================================
# gems for KCSD

# logger
gem 'logger', '1.2.8'

# Fog
# Universal API for many infrastructure cloud provider
# good supported for AWS EC2, Rackspace
# gem 'fog', '1.3.1'
gem 'fog', '1.5.0'



# Chef
gem 'chef', '10.12.0'
# gem 'chef-server', '10.12.0'

# support --json-attributes, which is not supported by offical knife-ec2 plugin from opscode
# these attributes will be merged into the first_boot variable by bootstrapping
# gem 'knife-ec2', :git => 'https://github.com/johntdyer/knife-ec2.git'
# gem 'knife-ec2', '0.5.12'

# Capistrano
# gem 'capistrano', '2.12.0'

# upload bootstrap script to Chef Server
# gem 'net-ssh', '2.5.2'

# chef (10.12.0) depends on net-ssh ~> 2.2.2
gem 'net-ssh', '>= 2.2.2'

# parallel
#gem 'parallel', '0.5.17'
gem 'parallel', '0.5.18'

# ======================================================================

gem 'rails', '3.2.6'


# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'sqlite3'


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.5'
  gem 'coffee-rails', '~> 3.2.2'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platform => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'
