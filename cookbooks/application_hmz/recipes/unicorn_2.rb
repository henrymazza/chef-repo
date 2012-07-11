# As instructed in https://github.com/damm/chef-unicorn.git

include_recipe "unicorn"
node.default[:unicorn][:worker_timeout] = 180  
node.default[:unicorn][:preload_app] = false  
node.default[:unicorn][:worker_processes] = 4 
node.default[:unicorn][:before_fork] = 'sleep 1'  
node.default[:unicorn][:port] = 8080
node.default[:unicorn][:gem_home] = nil
node.default[:unicorn][:stderr_path] = 'log/stderr.log'  
node.default[:unicorn][:stdout_path] = 'log/stdout.log'  
node.default[:unicorn][:logger] = 'log/unicorn.log'
node.default[:unicorn][:bluepill] = 'enabled'
node.default[:unicorn][:pid] = '/var/run/example.pid'
node.default[:unicorn][:process_name] = 'unicorn'
node.set[:unicorn][:options] = { :tcp_nodelay => true, :backlog => 4096 }

unicorn_config "example" do
  listen({ node[:unicorn][:port] => node[:unicorn][:options] })  
  working_directory '/data/example/current'
  worker_timeout node[:unicorn][:worker_timeout]  
  gem_home node[:unicorn][:gem_home]
  preload_app node[:unicorn][:preload_app]
  worker_processes node[:unicorn][:worker_processes]  
  before_fork node[:unicorn][:before_fork]   
  logger node[:unicorn][:logger]
  stderr_path node[:unicorn][:stderr_path]  
  stdout_path node[:unicorn][:stdout_path]
  pid node[:unicorn][:pid]
  owner "example"
  group "example"
  restart_command "kill -USR2 `cat /var/run/example.pid`"
  stop_command "kill `cat /var/run/example.pid`"
  start_grace_time "90"
  stop_grace_time "45"
  restart_grace_time "90"
  mem_usage_mb "250"
  cpu_usage_percent "90"
  process_name "unicorn"

end
