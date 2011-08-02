name "webserver"
description "The base role for systems that serve HTTP traffic, Rails ready."
run_list "recipe[rvm]", "recipe[nginx::passenger]"
