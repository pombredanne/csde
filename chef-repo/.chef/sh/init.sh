#!/usr/bin/env bash
set -e
set -x

init() {
  apt-get update -qq # only relevant info in stdout
  apt-get upgrade -qq
  apt-get install openjdk-6-jdk ruby1.9.1-full libsqlite3-dev wget ssl-cert libopenssl-ruby libxslt-dev libxml2-dev
  
  gem install rubygems-update
  update_rubygems
}

init