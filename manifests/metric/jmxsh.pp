class ganglia::metric::jmxsh (
  $ensure = 'present',
  $port   = 9001,
  $host   = 'localhost') {
  ganglia::module::python_git { 'jmxsh': pyconf => 'jmx-basic', }

  common::replace { "replace-jmx-port":
    file        => "${ganglia::params::conf_d}/jmxsh.pyconf",
    pattern     => 'value.*=.*1099.*',
    replacement => "value = '${port}'",
    require     => Ganglia::Module::Python_git['jmxsh'],
    notify      => Service['ganglia-monitor'],
  }

  file { '/usr/share/java/jmxsh.jar':
    ensure => $ensure ? {
      'present' => "${ganglia::params::git_mods}/jmxsh/extra/jmxsh.jar",
      before    => Ganglia::Module::Python_git['jmxsh'],
      default   => $ensure,
    }
  }
}