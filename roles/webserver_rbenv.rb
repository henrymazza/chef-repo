name "webserver_rbenv"
description "The base role for systems that serve HTTP traffic, Rails ready."
run_list "recipe[mysql]", "recipe[nginx]", "recipe[postfix]"
