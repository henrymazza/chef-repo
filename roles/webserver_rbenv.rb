name "webserver"
description "The base role for systems that serve HTTP traffic, Rails ready."
run_list "recipe[nginx]", "recipe[postfix]"
