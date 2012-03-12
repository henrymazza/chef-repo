#
# Cookbook Name:: resque
# Recipe:: default
#

include_recipe "runit"
include_recipe "redis"


worker_count = 4

apps = node.run_list.roles & search(:apps).map(&:id)

apps.each do |app|

  runit_service "#{app}-resque" do
    options = { :app_dir => "/var/www/apps/#{app}/current" }  
    template_name "resque"
  end

end

