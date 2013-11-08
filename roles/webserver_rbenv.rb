name "webserver_rbenv"
description "The base role for systems that serve HTTP traffic, Rails ready."

override_attributes(
  # default[:nginx][:gzip_http_version] = "1.1"
  :nginx => {
    :gzip_http_version => '1.0'
  }
)

run_list "recipe[mysql::server]", "recipe[nginx]", "recipe[postfix]";

