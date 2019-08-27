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

include_recipe 'iptables'
include_recipe 'redisio'
include_recipe 'redisio::enable'
include_recipe 'nodejs'

postgresql_client_install 'PostgreSQL Client' do
  version '9.4.22'
end

postgresql_server_install 'PostgreSQL Server install' do
  action :install
  version '9.4.22'
end

nginx_install 'default'

uni_ruby = "2.5.0"
uni_home = "/home/uni"

iptables_rule 'redis' do
  action :disable
end

iptables_rule 'http' do
  action :enable
end

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

directory '/home/uni/bin/' do
  owner "uni"
  group "apps"
end

file "/home/uni/bin/trails" do
  user 'uni'
  group 'apps'
  mode "0750"

  content <<-EOH
sudo tail -f /var/log/upstart/uni.log /home/uni/release/log/*.log
  EOH

end

directory "/home/uni/s3" do
  owner "uni"
  group "apps"
end

package "libpq-dev" # postgres???

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

uni_env = {
  'RAILS_VERSION' => '5.0.6',
  'REDIS_URL' => 'redis://localhost:6379/',
  'SKIP_EMBER' => 'true',
  'RAILS_ENV' => 'production',
  'PATH' => './bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
  'ACRAS_TOKEN' => data_bag_item('secrets', 'acras')['token'],
  'ACRAS_SERVER' => data_bag_item('secrets', 'acras')['server'],
  'SHOPIFY_KEY' => data_bag_item('secrets', 'shopify')['key'],
  'SHOPIFY_PASSWORD' => data_bag_item('secrets', 'shopify')['password'],
  'SHOPIFY_SHOP' => data_bag_item('secrets', 'shopify')['shop']
}

service 'uni' do
  action :disable
end

application "/home/uni/release" do
  action :deploy
  owner "uni"
  group "apps"

  ruby uni_ruby

  git "/home/uni/release/"do
    repository "git@github.com:henrymazza/uni.git"
    uni = search('apps', "id:uni").first
    deploy_key uni['deploy_key']

    revision node['uni']['revision']
  end

  environment uni_env

  directory 'public/files'
  directory 'log'

  file "/home/uni/release/.env" do
    user 'uni'
    group 'apps'
    mode '600'
    content uni_env.map{|k, v| "#{k}=#{v}"}.join("\n")
  end

  bundle_install do
    binstubs true
    without 'development test'
    deployment true
    user 'uni'
  end

  rails do
    migrate true
    precompile_assets false
  end

  template "/home/uni/release/config/database.yml" do
    source "database.yml.erb"
    owner "uni"
    group "apps"
  end

  puma do
    service_name 'uni'
    port 8082
  end

  nginx_site 'uni.conf' do
    template "load_balancer.conf.erb"
  end

end

poise_service_user 'uni'

poise_service 'uni-sidekiq-2' do
  directory '/home/uni/release'
  command <<-CMD
    /opt/ruby_build/builds/2.5.0/bin/ruby /opt/ruby_build/builds/2.5.0/bin/bundle exec /opt/ruby_build/builds/2.5.0/bin/ruby /home/uni/release/bin/sidekiq -e production
  CMD
  user 'uni'
  environment RAILS_ENV: 'production'
end

# Old service
runit_service "uni-sidekiq" do
  action :disable
end

# the config file was made by hand, so...
package 's3cmd'

cron "cookbooks_report" do
  action :create
  hour "22"
  minute "0"
  user "HMz"
  mailto "admin@ciadouniforme.com"
  command %Q{sudo -u uni pg_dump -F c uni > /tmp/uni.psql && \
    s3cmd put /tmp/uni.psql s3://ciadouniforme.com/backups/uni-`date -I`.psql}
end

logrotate_app "uni" do
  path "/home/uni/release/log/*.log"
  frequency "daily"
  create "644 uni apps"
  rotate 30
end
