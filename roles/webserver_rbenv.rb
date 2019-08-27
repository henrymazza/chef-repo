name "webserver_rbenv"
description "The base role for systems that serve HTTP traffic, Rails ready."

override_attributes(
  # default[:nginx][:gzip_http_version] = "1.1"
  "php-fpm" => {
    "pools" => {
      "default" => {
        :enable => true
      }
    }
  },
  :nginx => {
    :gzip_http_version => '1.0'
  },
  :postgresql => {
    version: "9.4"
  }
)

run_list "recipe[nginx]", "recipe[postfix]",
         "recipe[postgresql::server]", "recipe[php-fpm]"
