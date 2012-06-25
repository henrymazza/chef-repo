#
# Cookbook Name:: backup
# Recipe:: default
#
# Copyright 2011, Alastair Brunton
#
# MIT license
#

# Install backup, s3sync, fog, mail, whenever

package "libxslt" do
  package_name "libxslt-dev"
  action :install
end

package "libxml-dev" do
  package_name "libxml2-dev"
  action :install
end


['backup', 's3sync', 'fog', 'mail', 'whenever', 'popen4', 'parallel'].each do |gem_name|
  gem_package gem_name do
    action :install
    gem_binary   "/usr/local/rvm/bin/rvm all do gem"
  end
end

user node[:backup][:backup_user] do
  comment "Backup User"
  home "/home/#{node[:backup][:backup_user]}"
  system true
  gid "admin"
  supports :manage_home => true
end

['Backup', 'Backup/config'].each do |dir|
  execute "mkdir /home/#{node[:backup][:backup_user]}/#{dir}" do
    user node[:backup][:backup_user]
    only_if { !File.directory?("/home/#{node[:backup][:backup_user]}/#{dir}") }
  end
end

template "/home/#{node[:backup][:backup_user]}/Backup/config.rb" do
  owner node[:backup][:backup_user]
  source "config.rb.erb"
  variables(:config => node[:backup])
end


# Whenever config setup.
template "/home/#{node[:backup][:backup_user]}/Backup/config/schedule.rb" do
  owner node[:backup][:backup_user]
  source "schedule.rb.erb"
  variables(:config => node[:backup])
end

template "/etc/logrotate.d/whenever_log" do
  owner "root"
  source "logrotate.erb"
  variables(:backup_path => "/home/#{node[:backup][:backup_user]}/Backup")
  not_if { File.exists? "/etc/logrotate.d/whenever_log" }
end



