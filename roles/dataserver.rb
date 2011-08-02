name "dataserver"
description "The base role for MySQL server."
run_list "recipe[mysql::sever]"
