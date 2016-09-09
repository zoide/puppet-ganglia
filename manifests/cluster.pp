define ganglia::cluster (
  $port,
  $bind       = '0.0.0.0',
  $ensure     = 'present',
  $multicast  = false,
  $deaf       = 'no',
  $sflow_host = false,
  $sflow_port = false) {
  include ganglia::params
  $includes = false
  $cluster = $name
  $service = "ganglia-monitor.${name}"

  File {
    ensure => $ensure }

  @@file { "${ganglia::params::metacollects}/zz_${name}":
    content => "data_source '${name}' localhost:${port}\n",
    tag     => 'ganglia_metad_all',
    ensure  => $ensure;
  }

  file { "${ganglia::params::mconf_dir}/gmond.${name}.conf":
    ensure  => $ensure,
    content => template('ganglia/ganglia-monitor-conf.erb', 'ganglia/gmond-cluster.conf.erb', 'ganglia/gmond-udp-receive.conf.erb'
    ),
    owner   => 'ganglia',
    mode    => '0600',
  }
  $name_real = "gmond.${name}"

  file { "/etc/init.d/${service}":
    ensure  => $ensure,
    content => template('ganglia/gmond-init.d.erb'),
    mode    => '0755',
  }

  if $ensure == 'present' {
    service { $service:
      hasstatus => false,
      pattern   => "/usr/sbin/gmond --pid-file=/var/run/gmond.${name}.*",
      require   => [
        File["${ganglia::params::mconf_dir}/gmond.${name}.conf"],
        File["/etc/init.d/${service}"]],
      enable    => true,
      ensure    => 'running',
    }
  } else {
    service { $service:
      hasstatus => false,
      pattern   => "/usr/sbin/gmond --pid-file=/var/run/gmond.${name}.*",
      before    => File["/etc/init.d/${service}"],
      enable    => false,
      ensure    => 'stopped',
    }
  }
}
