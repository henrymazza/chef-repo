#
# Cookbook Name:: ip-echo
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
#

directory "/var/www/ip-echo/"

template "/var/www/ip-echo/ip-echo.rb" do
  source "ip-echo.rb"
  mode '0755'
end

iptables_rule "port_ip-echo"

runit_service "ip-echo"
