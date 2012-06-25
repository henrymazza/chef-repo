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
  :chef_client => {
    "server_url" => "https://api.opscode.com/organizations/officina",
    "validation_client_name" => "officina-validator",
    "init_style" => "runit"
  },
  :rvm => {
    "default_ruby" => '1.9.3-p125'
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
  "recipe[rvm]",
  "recipe[chef_handler]",
  "recipe[chef-client]",
  "recipe[hostname]", 
  "recipe[users::sysadmins]", 
  "recipe[sudo]", 
  "recipe[postfix]", 
  "recipe[ssh_known_hosts]",
  "recipe[iptables]",
  "recipe[denyhosts]",
  "recipe[backup]"
) 
