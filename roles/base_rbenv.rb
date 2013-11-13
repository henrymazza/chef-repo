name "base_rbenv"
description "The base role for systems that serve HTTP traffic, Rails ready. This is a modification to work with rbenv instead RVM."

default_attributes(
  "rbenv" => {
    'rubies'  => ['2.0.0-p247'],
    "global" => "2.0.0-p247",
    "gems" => {
      "2.0.0-p247" => [
        {'name' => 'mysql'},
        {'name' => 'bundler'},
        {'name' => 'rake', options: { force: true }}
      ]
    }
  },
  "authorization" => {
    "sudo" => {
      "groups" => ["admin", "wheel", "sysadmin"],
      "users" => ["HMz"],
      "passwordless" => true
    },
  }
)

override_attributes(
  # default['munin']['server_auth_method'] = 'openid'
  :munin => {
    "server_auth_method" => "other"
  },
  :chef_client => {
    "server_url" => "https://api.opscode.com/organizations/officina",
    "validation_client_name" => "officina-validator",
    "init_style" => "runit"
  }
)

run_list(
  "recipe[base]",
  "recipe[build-essential]",
  "recipe[iptables]",
  # put here so libmysqlclient-dev gets installed before mysql gem.
  "recipe[mysql::client]",
  "recipe[chef-client::delete_validation]",
  "recipe[runit]",
  "recipe[chef-client::config]",
  "recipe[ruby_build]",
  "recipe[rbenv::system]",
  "recipe[chef_handler]",
  "recipe[chef-client]",
  "recipe[hostname]",
  "recipe[users::sysadmins]",
  "recipe[sudo]",
  "recipe[postfix]",
  "recipe[ssh_known_hosts]",
  "recipe[denyhosts]",
  "role[monitoring]"
  # "recipe[munin::client]",
  # "recipe[munin::server]",
  # "recipe[backup]" TODO: make it RVMless
)
