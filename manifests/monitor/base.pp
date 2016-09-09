class ganglia::monitor::base (
  $ensure = 'present') {
  include 'ganglia::params'

  # metrics configuration
  File {
    owner   => 'root',
    mode    => '0700',
    force   => true,
    recurse => true,
    backup  => false,
  }

  $ens_dir = $ensure ? {
    'present' => 'directory',
    default   => $ensure,
  }

  file { $ganglia::params::metrics:
    ensure  => 'absent',
    force   => true,
    recurse => true,
  }

  Cron {
    user   => 'root',
    ensure => 'absent',
  }
  $pre_cmd = "if [ -e ${ganglia::params::metrics}/run-metrics.sh ]; then  ${ganglia::params::metrics}/run-metrics.sh"
  # mind
  # the
  # trailing
  # whitespace
  $post_cmd = ' fi' # space at the beginning



  cron {
    'ganglia-runmetrics-1':
      command => "${pre_cmd} ${ganglia::params::metrics_cron}/1;${post_cmd}",
      minute  => '*/1';

    "ganglia-runmetrics-5":
      command => "${pre_cmd} ${ganglia::params::metrics_cron}/5;${post_cmd}",
      minute  => '*/5';

    'ganglia-runmetrics-15':
      command => "${pre_cmd} ${ganglia::params::metrics_cron}/15;${post_cmd}",
      minute  => '*/15';

    'ganglia-runmetrics-30':
      command => "${pre_cmd} ${ganglia::params::metrics_cron}/30;${post_cmd}",
      minute  => '*/30';

    'ganglia-runmetrics-60':
      command => "${pre_cmd} ${ganglia::params::metrics_cron}/60;${post_cmd}",
      minute  => '*/60',
  }
}
