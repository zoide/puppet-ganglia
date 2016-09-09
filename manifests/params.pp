class ganglia::params {
  $user = $::kernel ? {
    'Darwin' => 'nobody',
    default  => 'ganglia'
  }
  $group = $::kernel ? {
    'Darwin' => 'wheel',
    default  => 'ganglia'
  }
  $metacollects = "${::puppet_vardir}/exported/ganglia-metad"
  $metrics = "${::puppet_vardir}/exported/ganglia-metrics"
  $metrics_cron = "${metrics}/cron"
  $metrics_py = $::kernel ? {
    'Darwin' => '/opt/local/lib/ganglia/python_modules',
    default  => '/usr/lib/ganglia/python_modules'
  }
  $mconf_dir = $::kernel ? {
    'FreeBSD' => '/usr/local/etc',
    'Darwin'  => '/opt/local/etc/ganglia',
    default   => '/etc/ganglia'
  }
  $gmond = $::kernel ? {
    'FreeBSD' => 'gmond',
    'Darwin'  => 'org.macports.ganglia',
    default   => 'ganglia-monitor',
  }
  $conf_d = "${mconf_dir}/conf.d"
  $git_mods = "{::puppet_vardir}/exported/gmond-python-modules-git"
}
