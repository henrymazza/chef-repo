#
# Cookbook Name:: aki_db
# Recipe:: default
#
# Copyright (C) 2015 YOUR_NAME
#
# All rights reserved - Do Not Redistribute
#
#

#aki_db_ruby = "2.1.5"

group "apps"

directory "/home/aki_db" do
  owner "aki_db"
  group "apps"
end

user "aki_db" do
  comment "AkiDB Application"
  gid "apps"
  home "/home/aki_db"
end

directory "/home/aki_db/logs/" do
  owner "aki_db"
  group "apps"
end

directory "/home/aki_db/app/shared" do
  owner "aki_db"
  group "apps"
end

directory "/home/aki_db/app/shared/log" do
  owner "aki_db"
  group "apps"
end

directory "/home/aki_db/app/shared/system" do
  owner "aki_db"
  group "apps"
end

execute "gem install unicorn"

application "aki_db" do
  action :deploy
  path "/home/aki_db/app"
  owner "aki_db"
  group "apps"

  revision "deploy"

  aki_db = search('apps', "id:aki2").first
  deploy_key aki_db['deploy_key']
  symlinks( {'system' => 'public/system', 'pids' => 'tmp/pids', 'log' => 'log'})

  repository "git@github.com:henrymazza/aki_db.git"

  rails do
    precompile_assets false
    database_template "database.yml.erb"
    bundler true
    bundle_command '/home/aki_db/.rbenv/shims/bundle'
  end

  unicorn do
    bundler true
    bundle_command '/home/aki_db/.rbenv/shims/bundle'
    port '3080'

    worker_processes 4
  end
end

