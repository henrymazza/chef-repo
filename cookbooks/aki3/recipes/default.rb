#
# Cookbook Name:: aki3
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
#
# (?) create aki3 home first
# (?) aki3 service should be aki3 owned? or apps group owned?
#
include_recipe 'libmysqlclient'
include_recipe 'php-fpm'
include_recipe 'acme'

#
# Pre-install SSL
#
# Set up contact information. Note the mailto: notation
node.override['acme']['contact'] = ['mailto:fabio@mazarotto.me']
# Real certificates please...
node.override['acme']['endpoint'] = 'https://acme-v01.api.letsencrypt.org'

site  = "blog.akivest.com.br"
site2 = "aki3.sampa3.officina.me"

directory "/etc/nginx/ssl/" do
  owner "root"
  group "root"
end

acme_selfsigned site do
  crt     "/etc/nginx/ssl/#{site}.crt"
  chain   "/etc/nginx/ssl/#{site}.pem"
  key     "/etc/nginx/ssl/#{site}.key"
  owner   "root"
  group   "root"
  notifies :restart, "service[nginx]", :immediate
end

acme_selfsigned site2 do
  crt     "/etc/nginx/ssl/#{site2}.crt"
  chain   "/etc/nginx/ssl/#{site2}.pem"
  key     "/etc/nginx/ssl/#{site2}.key"
  owner   "root"
  group   "root"
  notifies :restart, "service[nginx]", :immediate
end

#########################################################3

mysql2_chef_gem 'default' do
  action :install
end

group "apps"

directory "/home/aki3"

user "aki3" do
  comment "Aki3 Wordpress"
  gid "apps"
  home "/home/aki3"
end

directory "/home/aki3/www/" do
  owner "aki3"
  group "apps"
end

directory "/home/aki3/logs/" do
  owner "aki3"
  group "apps"
end

directory "/home/aki3/s3" do
  owner "aki3"
  group "apps"
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

mysql_database 'aki3' do
  connection mysql_connection_info
  action :create
end

mysql_database_user "aki3" do
  username 'aki3'
  connection mysql_connection_info
  password 'aki666pass'
  action :create
end

mysql_database_user "aki3" do
  username 'aki3'
  connection mysql_connection_info
  password 'aki666pass'
  action :grant
end

#########################################
# PHP
#########################################

# TODO: PHP 5.2 - Add the following source, reinstall php5,
#       and restart php-fpm.
#
# apt_repository "nginx-php" do
#   uri "http://ppa.launchpad.net/txwikinger/php5.2/ubuntu"
# end

template "#{node['nginx']['dir']}/wordpress.conf" do
  source   'wordpress-common.erb'
  owner    'root'
  group    'root'
  mode     00644
  cookbook 'aki3'
end

template "#{node['nginx']['dir']}/sites-available/aki3.conf" do
  source   'wordpress-sites.erb'
  owner    'root'
  group    'root'
  mode     00644
  cookbook 'aki3'
  variables(
    :name => 'aki3',
    :host => 'blog.akivest.com.br',
    :root => '/home/aki3/www/'
  )
end

nginx_site 'aki3.conf' do
  action :enable
  notifies :restart, "service[nginx]", :immediate
end

######################################
# Wordpress
######################################

apt_package 'php5-mysqlnd'

# Downloads and extracts latest wordpress version
# TODO: stick with only one version
tar_extract 'https://wordpress.org/wordpress-5.1.1.tar.gz' do
  target_dir '/home/aki3/www/'

  # prevent the command from running when the specified file already exists.
  creates File.join('/home/aki3/www/', 'index.php')

  user 'aki3'
  group 'apps'
  tar_flags [ '--strip-components 1' ]

  # looks like redundant
  not_if { ::File.exists?("/home/aki3/www/index.php") }
end

template "/home/aki3/www/wp-config.php" do
  source 'wp-config.php.erb'
  mode 0644
  variables(
    :db_name           => 'aki3',
    :db_user           => 'aki3',
    :db_password       => 'aki666pass',
    :db_host           => '127.0.0.1',
    :db_prefix         => 'wp_',
    :db_charset        => 'utf8',
    :db_collate        => '',
    :auth_key          => node['aki3']['keys']['auth'],
    :secure_auth_key   => node['aki3']['keys']['secure_auth'],
    :logged_in_key     => node['aki3']['keys']['logged_in'],
    :nonce_key         => node['aki3']['keys']['nonce'],
    :auth_salt         => node['aki3']['salt']['auth'],
    :secure_auth_salt  => node['aki3']['salt']['secure_auth'],
    :logged_in_salt    => node['aki3']['salt']['logged_in'],
    :nonce_salt        => node['aki3']['salt']['nonce'],
    :lang              => '',
    :allow_multisite   => false,
    :wp_config_options => {}
  )
  owner 'aki3'
  group 'apps'
  action :create
end

#######################################

acme_certificate site do
  crt     "/etc/nginx/ssl/#{site}.crt"
  key     "/etc/nginx/ssl/#{site}.key"
  wwwroot '/home/aki3/www'
end

acme_certificate site2 do
  crt     "/etc/nginx/ssl/#{site2}.crt"
  key     "/etc/nginx/ssl/#{site2}.key"
  wwwroot '/home/aki3/www'
end

#######################################

service 'nginx' do
  action :restart
end
