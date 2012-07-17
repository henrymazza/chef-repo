name "webserver_rbenv"
description "The base role for systems that serve HTTP traffic, Rails ready."
run_list "recipe[mysql::server]", "recipe[mysql::client]", "recipe[nginx]", "recipe[postfix]"
