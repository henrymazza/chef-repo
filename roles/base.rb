name "base"
description "The base role for systems that serve HTTP traffic, Rails ready."

default_attributes(
  "authorization" => {
  "sudo" => {
    "groups" => ["admin", "wheel", "sysadmin"],
    "users" => ["HMz"],
    "passwordless" => true
  }
} 
)

override_attributes(
  "chef_client" => {
    "server_url" => "https://api.opscode.com/organizations/officina",
    "validation_client_name" => "officina-validator",
    "init_style" => "runit"
  },
  "rvm" => {
    "default_ruby" => '1.9.2'
  }
)

run_list(
  "recipe[chef-client::delete_validation]",
  "recipe[runit]",
  "recipe[chef-client::config]",
  "recipe[rvm]",
  "recipe[chef_handler]",
  "recipe[chef-client]",
  "recipe[hostname]", 
  "recipe[users::sysadmins]", 
  "recipe[sudo]", 
  "recipe[postfix]", 
  "recipe[ssh_known_hosts]"
) 
