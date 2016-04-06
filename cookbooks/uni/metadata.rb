name             'uni'
maintainer       'YOUR_COMPANY_NAME'
maintainer_email 'YOUR_EMAIL'
license          'All rights reserved'
description      'Installs/Configures uni'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends "postgresql"
depends "rbenv"
depends "ruby_build"
depends "application"
depends "application_ruby"
depends "application_nginx"
depends "iptables"
depends "runit"
depends "redisio"
