#
# Cookbook Name:: aki2
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
#

rbenv_ruby "1.9.3-p194"

group "apps"

user "aki2" do
  comment "Aki2 Application"
  gid "apps"
  home "/home/aki2"
end

directory "/home/aki2/logs/"

# create a mysql database
mysql_database 'akivest' do
  connection ({:host => "localhost", :username => 'root', :password => node['mysql']['server_root_password']})
  action :create
  # database: akivest
  # username: akivest
  # password: aki666pass
  # socket: /var/run/mysqld/mysqld.sock
end

application "aki2" do
  path "/home/aki2/app"
  owner "aki2"
  group "apps"

  aki2 = search('apps', "id:aki2").first
  deploy_key aki2['deploy_key']

  repository "git@github.com:henrymazza/akivest.git"

  unicorn do
    # port or socket to make comunication between nginx and unicorn
    port "/tmp/unicorn.todo.sock"
    bundler true
  end

  nginx_load_balancer do
    static_files "/assets" => "images"
    # use our very personal nginx conf file 
    template "load_balancer.conf.erb"
  end
end
