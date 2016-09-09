class ganglia::metric::mysql_server ($ensure = 'present', $username = 'ganglia', $password = 'ganggaglia') {
  ganglia::module::python { 'mysqld':
    ensure    => $ensure,
    conf_name => 'mysql',
  }

  package { 'python-mysqldb': before => Ganglia::Module::Python['mysqld'] }

  Common::Replace {
    before  => Service['ganglia-monitor'],
    file    => '/etc/ganglia/conf.d/mysql.pyconf.disabled',
    notify  => Service['ganglia-monitor'],
    require => Ganglia::Module::Python['mysqld'],
  }

  if $ensure == 'present' {
    common::replace {
      'gmond-mysql-username':
        pattern     => 'your_user',
        replacement => $username;

      'gmond-mysql-password':
        pattern     => 'your_password',
        replacement => $password;
    }

    database_user { 'ganglia@localhost': password_hash => mysql_password($password), }

    exec { 'mysql -uroot -e "grant super,process on *.* to \'ganglia\'@\'localhost\'; flush privileges;"':
      refreshonly => true,
      subscribe   => Database_user['ganglia@localhost'],
    }
  }

}