#
# Cookbook Name:: cassandra
# Recipe:: setup_repos
#
# Copyright 2011, DataStax
#
# Apache License
#

###################################################
# 
# Setup Repositories
# 
###################################################

case node[:platform]
  
  # LHA
  # KCSDB uses only Ubuntu AMIs
  
  when "ubuntu", "debian"
    include_recipe "apt"

    # Find package codenames
    if node[:platform] == "debian"
      if node[:platform_version] == "6.0"
        node[:internal][:codename] = "squeeze"
      elsif node[:platform_version] == "5.0"
        node[:internal][:codename] = "lenny"
      end
    else
      node[:internal][:codename] = node['lsb']['codename']
    end

    # Adds the Cassandra repo:
    # deb http://www.apache.org/dist/cassandra/debian <07x|08x> main
    #if node[:setup][:deployment] == "08x" or node[:setup][:deployment] == "07x"
    
    # LHA
    # node[:setup][:deployment] is read from attributes/default.rb
    
    if node[:setup][:deployment] == "08x" or node[:setup][:deployment] == "07x" or node[:setup][:deployment] == "10x"  or node[:setup][:deployment] == "11x"   
      apt_repository "cassandra-repo" do
        uri "http://www.apache.org/dist/cassandra/debian"
        components [node[:setup][:deployment], "main"]
        # keyserver "keys.gnupg.net"
        # key "2B5C1B00"
        keyserver "pgp.mit.edu"
        key "4BD736A82B5C1B00"
        action :add
      end
    end

  when "centos", "redhat", "fedora"
    if node[:platform] == "fedora"
      distribution="Fedora"
    else
      distribution="EL"
    end

    # Add the DataStax Repo
    platformMajor = node[:platform_version].split(".")[0]
    filename = "/etc/yum.repos.d/datastax.repo"
    repoFile = "[datastax]" << "\n" <<
               "name=DataStax Repo for Apache Cassandra" << "\n" <<
               "baseurl=http://rpm.datastax.com/#{distribution}/#{platformMajor}" << "\n" <<
               "enabled=1" << "\n" <<
               "gpgcheck=0" << "\n"
    File.open(filename, 'w') {|f| f.write(repoFile) }

    # Install EPEL (Extra Packages for Enterprise Linux) repository
    platformMajor = node[:platform_version].split(".")[0]
    epelInstalled = File::exists?("/etc/yum.repos.d/epel.repo") or File::exists?("/etc/yum.repos.d/epel-testing.repo")
    if !epelInstalled
      case platformMajor
        when "6"
          execute "sudo rpm -Uvh http://download.fedora.redhat.com/pub/epel/6/#{node[:kernel][:machine]}/epel-release-6-5.noarch.rpm"
        when "5"
          execute "sudo rpm -Uvh http://download.fedora.redhat.com/pub/epel/5/#{node[:kernel][:machine]}/epel-release-5-4.noarch.rpm"
        when "4"
          execute "sudo rpm -Uvh http://download.fedora.redhat.com/pub/epel/4/#{node[:kernel][:machine]}/epel-release-4-10.noarch.rpm"
      end
    end

    execute "yum clean all"
end
