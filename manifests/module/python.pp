define ganglia::module::python ($ensure = 'present', $conf_replace = undef, $conf_name = undef) {
  include ganglia::params

  if $conf_replace != undef {
    validate_hash($conf_replace)
  }

  if $conf_name != undef {
    $conf_name_r = $conf_name
  } else {
    $conf_name_r = $name
  }
  $pres_r = $ensure ? {
    'present' => "${ganglia::params::conf_d}/${conf_name_r}.pyconf.disabled",
    default   => $ensure,
  }

  file { "${ganglia::params::conf_d}/${conf_name_r}.pyconf":
    ensure  => $pres_r,
    force   => true,
    notify  => Service[$ganglia::params::gmond],
    require => Exec['disable-all-python-plugins-initially']
  }

  if $ensure == 'present' and $conf_replace != undef {
    common::replace { "conf-replace-${conf_name_r}":
      file        => $pres_r,
      pattern     => $conf_replace['pattern'],
      replacement => $conf_replace['replacement'],
      before      => Service[$ganglia::params::gmond],
    }
  }
}

