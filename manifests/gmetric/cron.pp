# _Define:_ ganglia::gmetric::cron
# Manage a ganglia metric called via cron.
#
# _Parameters:_
#   $namevar
#   - The metric's name
#   $source = "puppet:///ganglia/metrics-cron/${namevar}"
#   - The source from where to get the metric.
#   $source_name = ''
#   - The name of the source file if it differs from ${namevar}
#   $runwhen = '1'
#   - At which points in time this metric should be run [1,5,15,30,60]
#   $ensure = 'present'
#   - {'present','absent'} whether or not this process should be monitored
#
# _Sample Usage:_
# 1. +ganglia::gmetric::cron{'smartctl': }+
#       - fetches smartctl and installs it in the ganglia::monitor.
#         This metric is then run every minute
#
# 1. +ganglia::gmetric::cron{'workusage':
#               runwhen => '60',
#       }+
#       - install a metric 'workusage' and run it every 60 minutes.
#
define ganglia::gmetric::cron (
  $metric_name = '',
  $source      = '',
  $source_name = '',
  $ensure      = 'present',
  $runwhen     = '1') {
  include 'ganglia::params'
  $name_real = $metric_name ? {
    ''      => $name,
    default => $metric_name
  }
  $sname = $source_name ? {
    ''      => $name_real,
    default => $source_name,
  }
  $source_real = $source ? {
    ''      => "ganglia/metrics-cron/${sname}",
    default => "${source}/${sname}",
  }

  case $runwhen {
    '1', '5', '15', '30', '60' : {
      debug("running every \"${runwhen}\" minutes")
    }
    default                    : {
      err('runwhen can be only one of: 1,5,15,30,60')
    }
  }

  file { "${ganglia::params::metrics_cron}/${runwhen}/${name_real}":
    source => "puppet:///modules/${source_real}",
    owner  => 'root',
    mode   => '0700',
    ensure => $ensure,
  }
}
