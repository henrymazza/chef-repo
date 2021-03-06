name "base_rbenv"
description "The base role for systems that serve HTTP traffic, Rails ready. This is a modification to work with rbenv instead RVM."

default_attributes(
  "set_fqdn" => '*.officina.me',
  "ruby_build" => {
    "update" => 'true'
  },
  "rbenv" => {
    'rubies'  => ['2.3.0', '2.0.0-p648', '2.5.0'],
    "global" => "2.3.0",
    "gems" => {
      "2.5.0" => [
        {'name' => 'bundler'},
        {'name' => 'rake'},
        {'name' => 'rack', "version" => "2.0.4"}
      ],
      "2.3.0" => [
        {'name' => 'bundler'},
        {'name' => 'rake'}
      ],
      "2.0.0-p648" => [
        {'name' => 'bundler'},
        {'name' => 'rake'}
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
  #"recipe[chef-client::delete_validation]",
  "recipe[runit]",
  "recipe[chef-client::config]",
  "recipe[ruby_build]",
  "recipe[rbenv::system]",
  "recipe[hostname]",
  "recipe[users::sysadmins]",
  "recipe[backstage]",
  "recipe[sudo]",
  "recipe[postfix]",
  # "recipe[ssh_known_hosts]",
  "role[monitoring]"
)
