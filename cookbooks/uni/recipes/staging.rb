#
# Cookbook Name:: uni
# Recipe:: Staging
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

include_recipe 'iptables'
include_recipe 'postgresql::server'
include_recipe 'redisio'
include_recipe 'redisio::enable'
include_recipe 'nodejs'
include_recipe 'nginx'

uni_staging_ruby = "2.5.0"
uni_staging_home = "/home/uni_staging"

group "apps"

user "uni_staging" do
  comment "Uni Application Staging"
  gid "apps"
  home uni_staging_home
  shell '/bin/bash'
end

directory uni_staging_home do
  owner "uni_staging"
  group "apps"
end

template "/home/uni_staging/.bashrc" do
  source "bashrc.erb"
  owner "uni_staging"
  group "apps"
end

directory "#{uni_staging_home}/bin" do
  owner "uni_staging"
  group "apps"
end

file "/home/uni_staging/bin/trails" do
  user 'uni_staging'
  group 'apps'
  mode "0750"

  content <<-EOH
sudo tail -f /var/log/upstart/uni_staging.log /home/uni_staging/app/log/*.log
  EOH

end

package "libpq-dev" # postgres???

execute "createdb uni_staging" do
  user 'postgres'
  returns [0, 1]
end
execute "createdb ibge_staging" do
  user 'postgres'
  returns [0, 1]
end

execute 'createuser uni_staging' do
  user 'postgres'
  returns [0, 1]
end

execute 'psql uni_staging -c "GRANT ALL PRIVILEGES ON DATABASE uni_staging to uni_staging; ALTER ROLE uni_staging SUPERUSER; ALTER DATABASE uni_staging OWNER TO uni_staging;"' do
  user 'postgres'
  returns [0, 1]
end

execute 'psql ibge -c "GRANT ALL PRIVILEGES ON DATABASE ibge to uni_staging; ALTER ROLE uni_staging SUPERUSER;"' do
  user 'postgres'
  returns [0, 1]
end

uni_staging_env = {
  'RAILS_VERSION' => '5.0.6',
  'REDIS_URL' => 'redis://localhost:6380/',
  'SKIP_EMBER' => 'true',
  'RAILS_ENV' => 'production',
  'PATH' => './bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
  'ACRAS_TOKEN' => 'EygjMLvmjdXmbijvi3PQajLJDED8Kfyg',
  'ACRAS_SERVER' => 'producao.acrasnfe.acras.com.br'
}

file "/home/uni_staging/app/.env" do
  user 'uni_staging'
  group 'apps'
  mode '600'
  content uni_staging_env.map{|k, v| "#{k}=#{v}"}.join("\n")
end


# ruby_runtime uni_staging_ruby

application "/home/uni_staging/app/" do
  action :deploy
  owner "uni_staging"
  group "apps"

  ruby uni_staging_ruby

  git "/home/uni_staging/app/"do
    repository "git@github.com:henrymazza/uni.git"
    uni = search('apps', "id:uni").first
    deploy_key uni['deploy_key']

    revision node['uni']['revision']
  end

  # Rails resource uses it internally
  environment uni_staging_env

  # it's supposed to be ok with the defaults
  # symlinks( {'log/production.log' => 'log', 'pids' => 'tmp', 'ibge.sqlite3' => 'db/ibge.sqlite3', 'files' => 'public/files'})
  directory 'public/files'

  bundle_install do
    binstubs true
    without 'development test'
    deployment true
    user 'uni_staging'
  end

  template "/home/uni_staging/app/config/database.yml" do
    source "database_staging.yml.erb"
    owner "uni_staging"
    group "apps"
  end

  rails do
    migrate false
    precompile_assets false
  end

  puma do
    service_name 'uni_staging'
    # port or socket to make comunication between nginx and unicorn
    port "8081"
  end

  nginx_site 'uni_staging.conf' do
    template 'nginx_staging.conf.erb'
  end
end
