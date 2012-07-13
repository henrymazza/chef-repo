name "base_rbenv"
description "The base role for systems that serve HTTP traffic, Rails ready. This is a modification to work with rbenv instead RVM."

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
  :chef_client => {
    "server_url" => "https://api.opscode.com/organizations/officina",
    "validation_client_name" => "officina-validator",
    "init_style" => "runit"
  },
  :backup => {
    :backup_user => 'backup_agent',
    :mail => {
      :from_address => "backup@officina.me",
      :to_address   => "fabio.mazarotto@me.com",
      :domain       => "officina.me"
    },
		:s3 => {
      :sync_directories => ["/home"],
      :aws_access_key => 'AKIAIKLAZHM3GFTB7HSQ',
      :aws_secret_key => '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',
      :bucket_name => 'officina-backups'
    },
    :database => {
      :databases => ['mysql']
    }
  }
)

run_list(
  "recipe[chef-client::delete_validation]",
  "recipe[runit]",
  "recipe[chef-client::config]",
  "recipe[rbenv::system]",
  "recipe[chef_handler]",
  "recipe[chef-client]",
  "recipe[hostname]", 
  "recipe[users::sysadmins]", 
  "recipe[sudo]", 
  "recipe[postfix]", 
  "recipe[ssh_known_hosts]",
  "recipe[iptables]",
  "recipe[denyhosts]"
  # "recipe[backup]" TODO: make it RVMless
) 
