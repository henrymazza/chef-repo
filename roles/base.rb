name "base"
description "The base role for systems that serve HTTP traffic, Rails ready."
run_list "recipe[hostname]", "recipe[users::sysadmins]", "recipe[sudo]", "recipe[postfix]"
default_attributes "authorization" => {
  "sudo" => {
    "groups" => ["admin", "wheel", "sysadmin"],
    "users" => ["HMz"],
    "passwordless" => true
  }
}
  
