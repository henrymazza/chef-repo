#
# Cookbook Name:: resque
# Recipe:: default
#

include_recipe "runit"
include_recipe "redis"


worker_count = 4

apps = node.run_list.roles & search(:apps).map(&:id)

apps.each do |app|
  rvm_ruby = search(:apps, "id:#{app}").first['rvm_ruby']
  runit_service "#{app}-resque" do
    template_name "resque"
    options({
      :app_dir => "/var/www/apps/#{app}/current",
      :app_ruby => rvm_ruby
    })
  end
  # execute "kill -QUIT -`pgrep -f 'runsv #{app['id']}-resque'` && true" do
  # => the above is not trustable, the below one is a little harsh 
  execute "pgrep -f resque | xargs -l sudo kill" do
    user "root"
    ignore_failure true
    action :nothing
    # subscribes :restart, "service[#{app}-resque]"
  end
end
