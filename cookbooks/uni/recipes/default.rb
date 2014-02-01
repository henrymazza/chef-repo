#
# Cookbook Name:: uni
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
#
# Cookbook Name:: uni
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

uni_ruby = "2.0.0-p195"
uni_home = "/home/uni"

group "apps"

directory uni_home do
  owner "uni"
  group "apps"
end

user "uni" do
  comment "Uni Application"
  gid "apps"
  home uni_home
  shell '/bin/bash'
end

template "/home/uni/.bashrc" do
  source "bashrc.erb"
  owner "uni"
  group "apps"
end

directory "/home/uni/logs/" do
  owner "uni"
  group "apps"
end

directory "/home/uni/app/shared/log/" do
  owner "uni"
  group "apps"
end

directory "/home/uni/s3" do
  owner "uni"
  group "apps"
end

rbenv_ruby uni_ruby

package "imagemagick"
package "nodejs"

gem_package "mysql" # install mysql on chef's running ruby environment

mysql_connection_info = ({:host => "localhost", :username => 'root', :password => node['mysql']['server_root_password']})


#########################################
# create a mysql database and mysql user
#########################################

mysql_database 'uni' do
  node.default['mysql']['bind_address'] = 'localhost'
  connection mysql_connection_info
  database_name 'uni'
  action :create
end

mysql_database_user 'uni' do
  connection mysql_connection_info
  password 'uni666pass'
  action :create
end

mysql_database_user 'uni' do
  connection mysql_connection_info
  password 'uni666pass'
  database_name 'uni'
  action :grant
end

#################################################
# create a mysql database and mysql user for IBGE
#################################################

mysql_database 'ibge' do
  node.default['mysql']['bind_address'] = 'localhost'
  connection mysql_connection_info
  database_name 'ibge'
  action :create
end

mysql_database_user 'uni' do
  connection mysql_connection_info
  database_name 'ibge'
  action :grant
end

#################################################
# create a mysql database and mysql user for IBGE
#################################################

execute "createdb uni" do
  user 'postgres'
  returns [0, 1]
end
execute 'createuser uni' do
  user 'postgres'
  returns [0, 1]
end
execute 'psql uni -c "GRANT ALL PRIVILEGES ON DATABASE uni to uni; ALTER ROLE uni SUPERUSER; ALTER DATABASE uni OWNER TO uni;"' do
  user 'postgres'
  returns [0, 1]
end
execute "createdb ibge" do
  user 'postgres'
  returns [0, 1]
end
execute 'psql ibge -c "GRANT ALL PRIVILEGES ON DATABASE ibge to uni; ALTER ROLE uni SUPERUSER; ALTER DATABASE uni OWNER TO uni;"' do
  user 'postgres'
  returns [0, 1]
end

file "/home/uni/bundle_wrapper.sh" do
  user 'uni'
  group 'apps'
  mode "0750"

  content <<-EOH
#!/bin/bash

export RAILS_ENV=production
source /etc/profile.d/rbenv.sh

exec bundle $@
  EOH

end

application "uni" do
  action :deploy
  path "/home/uni/app"
  owner "uni"
  group "apps"

  migrate true
  revision "master"

  # Rails resource uses it internally
  environment ({
    'RAILS_ENV' => 'production',
    'PATH' => './bin:/usr/local/rbenv/bin:/usr/local/rbenv/shims:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    'JUJUBA' => 'assassina'
  })

  uni = search('apps', "id:uni").first
  deploy_key uni['deploy_key']
  # it's supposed to be ok with the defaults
  symlinks( {'log' => 'log', 'ibge.sqlite3' => 'db/ibge.sqlite3'})

  repository "git@github.com:henrymazza/uni.git"

  before_symlink do
    current_release = release_path

    log `pwd && ls #{current_release}`

    execute "rm database.yml" do
      user          "uni"
      group         "apps"
      cwd           "#{ current_release }/config/"
    end

    # this code is here in the assumption that if it doesn't exist the symlink will fail
    execute "rm -rf #{current_release}/public/system #{current_release}/tmp/pids #{current_release}/log" do
      user          "uni"
      group         "apps"
    end
    log `pwd && ls #{current_release}`
  end

  before_restart do
    current_release = release_path
    # load database if it haven't being done yet
    execute " bin/rake bootstrap:all" do
      environment ({
        'RAILS_ENV' => 'production',
        'PATH' => './bin:/usr/local/rbenv/bin:/usr/local/rbenv/shims:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
      })
      cwd current_release
      user "uni"
      group "apps"
    end

  end

  rails do
    precompile_assets true # (???) it fails if chef's embedded ruby is less than 2.0
    bundler true
    bundle_command "/home/uni/bundle_wrapper.sh"
    database_template "database.yml.erb"
  end

  unicorn "/etc/unicorn/" do
    # port or socket to make comunication between nginx and unicorn
    port "/tmp/unicorn2.todo.sock"
    bundler true
    worker_processes 4
    preload_app true
  end

  nginx_load_balancer do
    static_files "/assets" => "images"
    # use our very personal nginx conf file
    template "load_balancer.conf.erb"
  end

  after_restart do
  end

end

# the config file was made by hand, so...
package 's3cmd'

cron "cookbooks_report" do
  action :create
  hour "22"
  minute "0"
  user "HMz"
  mailto "admin@ciadouniforme.com"
  command %Q{sudo -u uni pg_dump uni > /tmp/uni.psql && \
    s3cmd put /tmp/uni.psql s3://ciadouniforme.com/backups/uni-`date -I`.psql}
end

