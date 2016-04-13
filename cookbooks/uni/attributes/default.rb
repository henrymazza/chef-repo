set['postgresql']['version'] = '9.4'
set['postgresql']['enable_pgdg_apt'] = true
set['postgresql']['dir'] = "/etc/postgresql/9.4/main"
set['postgresql']['config']['data_directory'] = "/var/lib/postgresql/9.4/main"
set['postgresql']['config']['hba_file'] = "/etc/postgresql/9.4/main/pg_hba.conf"
set['postgresql']['config']['ident_file'] = "/etc/postgresql/9.4/main/pg_ident.conf"
set['postgresql']['config']['external_pid_file'] = "/var/run/postgresql/9.4-main.pid"
set['postgresql']['config']['ssl_key_file']  = "/etc/ssl/private/ssl-cert-snakeoil.key"
set['postgresql']['config']['ssl_cert_file'] = "/etc/ssl/certs/ssl-cert-snakeoil.pem"
set['postgresql']['client']['packages']  = ["postgresql-client-9.4"]
set['postgresql']['server']['packages']  = ["postgresql-9.4"]
set['postgresql']['contrib']['packages'] = ["postgresql-contrib-9.4"]
set['redisio']['requirepass'] = 'nsxf969'
default['uni']['revision'] = 'master'
set['unicorn']['options'] = nil

