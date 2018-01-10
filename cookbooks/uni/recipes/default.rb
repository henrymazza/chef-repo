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

include_recipe "iptables"
include_recipe "postgresql::server"
include_recipe "redisio"
include_recipe "redisio::enable"
include_recipe 'nodejs'

iptables_rule 'redis' do
  action :disable
end
iptables_rule 'http' do
  action :enable
end

uni_ruby = "2.3.0"
uni_home = "/home/uni"

group "apps"

user "uni" do
  comment "Uni Application"
  gid "apps"
  home uni_home
  shell '/bin/bash'
end

directory uni_home do
  owner "uni"
  group "apps"
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
  recursive true
  owner "uni"
  group "apps"
end

directory "/home/uni/app/shared/files/" do
  recursive true
  owner "uni"
  group "apps"
end

directory "/home/uni/s3" do
  owner "uni"
  group "apps"
end

rbenv_ruby uni_ruby

rbenv_gem "sass" do
  rbenv_version uni_ruby
  version "3.4.12"
  action :install
end

package "libpq-dev" # postgres???
package "imagemagick"

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

export REDIS_URL=redis://localhost/
export SKIP_EMBER=true
export RAILS_ENV=production
export ACRAS_TOKEN=#{data_bag_item('secrets', 'acras')['token']}
export ACRAS_SERVER=#{data_bag_item('secrets', 'acras')['server']}
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
  revision node['uni']['revision']

  restart_command do
    execute "service uni restart"
    user "root"
  end

  # Rails resource uses it internally
  environment({
    'REDIS_URL' => 'redis://localhost/',
    'SKIP_EMBER' => 'true',
    'RAILS_ENV' => 'production',
    'PATH' => './bin:/usr/local/rbenv/bin:/usr/local/rbenv/shims:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    'JUJUBA' => 'assassina',
    'ACRAS_TOKEN' => 'EygjMLvmjdXmbijvi3PQajLJDED8Kfyg',
    'ACRAS_SERVER' => 'producao.acrasnfe.acras.com.br'
  })

  uni = search('apps', "id:uni").first
  deploy_key uni['deploy_key']
  # it's supposed to be ok with the defaults
  symlinks( {'log/production.log' => 'log', 'ibge.sqlite3' => 'db/ibge.sqlite3', 'files' => 'public/files'})

  repository "git@github.com:henrymazza/uni.git"

  before_symlink do
    current_release = release_path

    log `pwd && ls #{current_release}`

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
    database_template "database.yml.erb"
    bundle_command "/home/uni/bundle_wrapper.sh"
    #bundle_command "bin/bundle"
  end


  unicorn "/etc/unicorn/" do
    # port or socket to make comunication between nginx and unicorn
    listen({ "/tmp/unicorn2.todo.sock" => nil})
    #port "/tmp/unicorn2.todo.sock"
    options nil
    worker_timeout 1200
    bundler true
    stderr_path "/home/uni/logs/unicorn.stderr.log"
    stdout_path "/home/uni/logs/unicorn.stdout.log"
    preload_app true
    worker_processes 1
  end

  nginx_load_balancer do
    static_files "/assets" => "images"
    # use our very personal nginx conf file
    template "load_balancer.conf.erb"
  end
end

runit_service "uni-sidekiq"

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

logrotate_app "uni" do
  cookbook "logrotate"
  path "/home/uni/app/shared/log/production.log"
  frequency "daily"
  create "644 uni apps"
  rotate 30
end
