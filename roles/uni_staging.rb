name "uni_staging"
description "instals redis for staging and production"

run_list *%w[
  recipe[redisio]
  recipe[redisio::enable]
]

default_attributes({
                     'redisio' => {
                       'servers' => [
                         {'port' => '6379', 'address' => '127.0.0.1'},
                         {'port' => '6380', 'address' => '127.0.0.1'}
                       ]
                     }
                   })
