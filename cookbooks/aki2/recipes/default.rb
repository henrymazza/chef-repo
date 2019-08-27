#
# Cookbook Name:: aki2
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
#
# (?) create aki2 home first
# (?) aki2 service should be aki2 owned? or apps group owned?
#
# TODO: Switch to `ruby_rbenv (2019)` cookbook instead of `rvenv (2013)`
#
include_recipe 'libmysqlclient'

mysql2_chef_gem 'default' do
  action :install
end

aki2_ruby = "2.0.0-p648"

group "apps"

directory "/home/aki2"

user "aki2" do
  comment "Aki2 Application"
  gid "apps"
  home "/home/aki2"
end

directory "/home/aki2/logs/" do
  owner "aki2"
  group "apps"
end

directory "/home/aki2/s3" do
  owner "aki2"
  group "apps"
end

rbenv_ruby aki2_ruby
ruby_rbenv aki2_ruby

package "imagemagick"

gem_package "mysql" # install mysql on chef's running ruby environment
rbenv_gem 'mysql' do
  rbenv_version aki2_ruby
end

mysql_service 'default' do
  bind_address '0.0.0.0'
  port '3306'
  initial_root_password node['mysql']['server_root_password']
  action [:create, :start]
end

mysql_connection_info = ({:port => 3306, :host => "127.0.0.1", :username => 'root', :password => node['mysql']['server_root_password']})


#########################################
# create a mysql database and mysql user
#########################################

mysql_database 'akivest' do
  connection mysql_connection_info
  action :create
end

mysql_database_user "aki2" do
  username 'aki2'
  connection mysql_connection_info
  password 'aki666pass'
  action :create
end

mysql_database_user "aki2" do
  username 'aki2'
  connection mysql_connection_info
  password 'aki666pass'
  action :grant
end

#######################################################################
# If mysql_database creates the table, download and restore database
#######################################################################

# TODO the timestamp must be dynamically defined
#s3_aware_remote_file "/home/aki2/s3/aki2_database.tar" do
  #source "s3-sa-east-1://officina-akivest2/backups/aki2_database/2012.09.18.13.47.48/aki2_database.tar"
  #access_key_id "AKIAIXIWLUD7NQQODZJA"
  #secret_access_key "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"
  #owner "root"
  #group "root"
  #mode 0644
  #action :nothing

  #subscribes :create, resources(:mysql_database => "akivest")
#end

#execute "untar database" do
  #command "tar xvf aki2_database.tar"
  #user "aki2"
  #group "apps"
  #cwd "/home/aki2/s3/"
  #action :nothing

  #subscribes :run, resources(:s3_aware_remote_file => "/home/aki2/s3/aki2_database.tar")
#end

#execute "restore database" do
  #command "mysql -u #{mysql_connection_info[:username]} -p#{mysql_connection_info[:password]} akivest < aki2_database/databases/MySQL/akivest.sql"
  #cwd "/home/aki2/s3/"
  #action :nothing

  #subscribes :run, resources(:execute => "untar database")
#end

#######################################################################
# If mysql_database creates the table, download and restore correspondent system files
#######################################################################

# TODO the timestamp must be dynamically defined
#s3_aware_remote_file "/home/aki2/s3/aki2_system_backup.tar" do
  #source "s3-sa-east-1://officina-akivest2/backups/aki2_files/2012.09.18.13.47.42/aki2_files.tar"
  #access_key_id "AKIAIXIWLUD7NQQODZJA"
  #secret_access_key "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"
  #owner "root"
  #group "root"
  #mode 0644
  #action :nothing

  #subscribes :create, resources(:mysql_database => 'akivest')
#end

#execute "untar system backup" do
  #command "tar xvf aki2_system_backup.tar"
  #cwd "/home/aki2/s3/"
  #user "aki2"
  #group "apps"
  #action :nothing
  #subscribes :run, resources(:s3_aware_remote_file => '/home/aki2/s3/aki2_system_backup.tar')
#end

file "/home/aki2/bundle_wrapper.sh" do
  user 'aki2'
  group 'apps'
  mode "0750"

  content <<-EOH
#!/bin/bash

source /etc/profile.d/rbenv.sh

exec bundle $@
  EOH

end

# symlinks( {'system' => 'public/system', 'pids' => 'tmp/pids', 'log/production.log' => 'log'})

# link '/home/aki2/app/current/public/system' do
#   to '/home/aki2/app/shared/system/'
# end

# link '/home/aki2/app/pids' do
#   to '/home/aki2/app/tmp/pids'
# end

# link '/home/aki2/app/log/production.log' do
#   to '/home/aki2/app/log'
# end


# TODO untar file and move backup to place at 'shared_path'
application "/home/aki2/release/" do
  action :deploy
  path "/home/aki2/app"
  owner "aki2"
  group "apps"

  # revision "master"

  git "/home/uni_staging/app/"do
    repository  "git@github.com:henrymazza/akivest.git"
    aki2 = search('apps', "id:aki2").first
    deploy_key aki2['deploy_key']

    revision node['aki2']['revision']
  end

  before_symlink do
    current_release = release_path

    # Create a local variable for the node so we'll have access to
    # the attributes
    deploy_node = node

    # A local variable with the deploy resource.
    deploy_resource = new_resource

    log `pwd && ls #{current_release}`

    #execute "rm database.yml" do
      #user          "aki2"
      #group         "apps"
      #cwd           "#{ current_release }/config/"
    #end
    # this code is here in the assumption that if it doesn't exist the symlink will fail
    execute "rm -rf #{current_release}/public/system #{current_release}/tmp/pids #{current_release}/log/prodution.log" do
      user          "aki2"
      group         "apps"
    end
    log `pwd && ls #{current_release}`
  end

  rails do
    bundler true
    bundle_command "/home/aki2/bundle_wrapper.sh"
    precompile_assets true
    database_template "database.yml.erb"
  end

  unicorn do
    options nil
    listen({"/tmp/unicorn.todo.sock" => nil})

    worker_processes 1
  end

  nginx_load_balancer do
    static_files "/assets" => "images"
    # use our very personal nginx conf file
    template "load_balancer.conf.erb"
  end

  after_restart do
    "cd #{release_path} && whenever --update-crontab aki2"
  end

end

logrotate_app "aki2" do
  cookbook "logrotate"
  path "/home/aki2/app/shared/log/production.log"
  frequency "daily"
  rotate 30
  create "644 aki2 apps"
end
