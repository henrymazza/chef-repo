name "appserver"
description ""
run_list "recipe[mysql::client]", "recipe[rails]"
