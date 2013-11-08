package 'cpulimit'

node.override['chef_client']['interval'] = 21600 # 6 hours, will update the template in the second execution

runit_service 'chef-client-limiter' do
  subscribes :restart, resources(:service=> "chef-client"), :immediately
end



