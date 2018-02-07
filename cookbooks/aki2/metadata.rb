name             "aki2"
maintainer       "YOUR_COMPANY_NAME"
maintainer_email "YOUR_EMAIL"
license          "All rights reserved"
description      "Installs/Configures aki2"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.1"
depends "base"
depends "iptables"
depends "rbenv"
depends "database"
depends "application"
depends "application_ruby"
# depends "application_nginx"
depends 'libmysqlclient', '~> 0.1.0'
depends 'mysql2_chef_gem'
depends "mysql"
