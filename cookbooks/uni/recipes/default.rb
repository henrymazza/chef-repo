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
include_recipe "nodejs::nodejs_from_binary"

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

package "libpq-dev"
package "imagemagick"

nodejs_npm "bower" do
  not_if "ls /usr/local/bin/bower"
end
nodejs_npm "ember-cli" do
  not_if 'ls /usr/bin/ember'
end

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
  action :force_deploy
  path "/home/uni/app"
  owner "uni"
  group "apps"

  migrate true
  revision "master"

  restart_command do
    execute "service uni restart"
    user "root"
  end

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
    precompile_assets false # (???) it fails if chef's embedded ruby is less than 2.0
    bundler true
    database_template "database.yml.erb"
    bundle_command "/home/uni/bundle_wrapper.sh"
    #bundle_command "bin/bundle"
  end


  unicorn "/etc/unicorn/" do
    # port or socket to make comunication between nginx and unicorn
    port "/tmp/unicorn2.todo.sock"
    worker_timeout 120
    bundler true
    worker_processes 6
    stderr_path "/home/uni/logs/unicorn.stderr.log"
    stdout_path "/home/uni/logs/unicorn.stdout.log"
    preload_app true
  end

  nginx_load_balancer do
    static_files "/assets" => "images"
    # use our very personal nginx conf file
    template "load_balancer.conf.erb"
  end

  before_migrate do
    #nodejs_npm "install npm from package.json" do
      #path "#{release_path}/frontend/"# The root path to your project, containing a package.json file
      #json true
      #user "uni"
      #options ['--production'] # Only install dependencies. Skip devDependencies
    #end
    execute "npm install at frontend" do
      cwd "#{release_path}/frontend/"
      command 'npm install'
      environment ({'HOME' => '/home/uni'})
      user 'uni'
      group 'apps'
      ignore_failure true
    end
    execute "bower install at frontend" do
      cwd "#{release_path}/frontend/"
      command 'bower install'
      environment ({'HOME' => '/home/uni'})
      user 'uni'
      group 'apps'
    end
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
