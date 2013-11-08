#
# Cookbook Name:: domcarlo
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
#
# (?) create domcarlo home first
# (?) domcarlo service should be domcarlo owned? or apps group owned?
#

package "nodejs"

ruby_version = "2.0.0-p247"

group "apps"

directory "/home/domcarlo"

user "domcarlo" do
  comment "domcarlo Application"
  gid "apps"
  home "/home/domcarlo"
end

directory "/home/domcarlo/logs/" do
  owner "domcarlo"
  group "apps"
end

rbenv_ruby ruby_version

application "domcarlo" do
  # action :force_deploy
  path "/home/domcarlo/app"
  owner "domcarlo"
  group "apps"

  revision "master"

  domcarlo = search('apps', "id:domcarlo").first
  deploy_key domcarlo['deploy_key']
  symlinks( {'system' => 'public/system', 'pids' => 'tmp/pids', 'log' => 'log'})

  repository "git@github.com:henrymazza/domcarlo.git"

  rails do
    precompile_assets true
    gems ["bundler", "rake"]
    database_template "database.yml.erb"
  end

  unicorn do
    # port or socket to make comunication between nginx and unicorn
    port "/tmp/unicorn.todo.sock"
    environment "PATH" => "./bin:/usr/local/rbenv/bin:/usr/local/rbenv/shims:/usr/local/bin"
    bundler true
    stderr_path "/home/domcarlo/logs/unicorn.stderr.log"
    stdout_path "/home/domcarlo/logs/unicorn.stdout.log"
    worker_processes 1
  end

  nginx_load_balancer do
    # use our very personal nginx conf file
    template "load_balancer.conf.erb"
  end

end
