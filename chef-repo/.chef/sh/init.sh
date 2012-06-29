#!/usr/bin/env bash
set -e
set -x

init() {
  apt-get update -qq # only relevant info in stdout
  apt-get upgrade -qq
  apt-get install nodejs wget ssl-cert openjdk-6-jdk ruby1.9.1-full libsqlite3-dev libopenssl-ruby libxslt-dev libxml2-dev -qq
  
  gem install rubygems-update
  update_rubygems
  
  gem install bundler -v '1.14'
}

init