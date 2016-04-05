#
# Cookbook Name:: backstage
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "iptables"

iptables_rule 'ssh' do
  action :enable
end

template '/home/HMz/.screenrc' do
  source 'screenrc.erb'
  owner 'HMz'
end
