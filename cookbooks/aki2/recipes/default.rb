#
# Cookbook Name:: aki2
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
#

group "apps"

user "aki2" do
  comment "Aki2 Application"
  gid "apps"
  home "/home/aki2"
end

application "aki2" do
  path "/home/aki2/app"
  owner "aki2"
  group "apps"

  aki2 = search('apps', "id:aki2").first
  deploy_key aki2['deploy_key']

  repository "git@github.com:henrymazza/akivest.git"

  rails do
    # Rails-specific configuration
  end

  nginx_load_balancer do
    static_files "/assets" => "images"
    # use our very personal nginx conf file 
    template "load_balancer.conf.erb"
    port "/tmp/unicorn.todo.sock"
  end
end
