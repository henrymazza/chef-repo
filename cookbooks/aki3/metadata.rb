name             "aki3"
maintainer       "officina me"
maintainer_email "fabio@mazarotto.me"
license          "All rights reserved"
description      "Installs/Configures aki3"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.1"
depends 'base'
depends 'iptables'
depends 'database'
depends 'openssl'
depends 'tar'
depends 'apt'
depends 'acme'

depends 'libmysqlclient', '~> 0.1.0'
depends 'mysql2_chef_gem'
depends 'mysql'

depends 'php-fpm'
depends 'nginx'
