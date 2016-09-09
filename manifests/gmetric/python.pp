# _Define:_ ganglia::gmetric::python
# Manage a ganglia python metric (also known module).
#
# _Parameters:_
#   $namevar
#   - The metric's name
#   $source = "puppet:///ganglia/metrics-py/${namevar}.py"
#   - The source from where to get the metric.
#  $additional_lib = ''
#   - additional library needed by this module
# $additional_lib_source = 'ganglia/metrics-py'
# - from where to get the addtional library
#   $ensure = 'present'
#   - {'present','absent'} whether or not this process should be monitored
#
# _Sample Usage:_
# 1. +ganglia::gmetric::python{'mysql':
#         additional_lib => 'DBUtil.py',
#       }+
#       - installs the mysql.py module and its requirement DBUtil.py from
#         puppet:///ganglia/metrics-py/
#
define ganglia::gmetric::python (
  $source                = '',
  $ensure                = 'present',
  $additional_lib        = '',
  $additional_lib_source = 'ganglia/metrics-py') {
  include 'ganglia::params'
  $source_real = $source ? {
    ''      => "ganglia/metrics-py/${name}.py",
    default => "${source}/${name}.py",
  }

  if defined(File[$ganglia::params::metrics_py]) {
    debug('already defined.')
  } else {
    file { $ganglia::params::metrics_py: ensure => 'directory', }
  }

  if defined(File["${ganglia::params::mconf_dir}/conf.d"]) {
    debug('already defined.')
  } else {
    file { "${ganglia::params::mconf_dir}/conf.d":
      ensure  => $ensure ? {
        'present' => 'directory',
        default   => $ensure,
      },
      force   => true,
      recurse => true,
    }
  }

  file {
    "${ganglia::params::metrics_py}/${name}.py":
      ensure  => $ensure,
      source  => "puppet:///modules/${source_real}",
      require => File[$ganglia::params::metrics_py],
      notify  => Service[$ganglia::params::gmond];

    "${ganglia::params::mconf_dir}/conf.d/${name}.pyconf":
      ensure  => $ensure,
      source  => "puppet:///modules/${source_real}conf",
      require => [
        File["${ganglia::params::metrics_py}/${name}.py"],
        File["${ganglia::params::mconf_dir}/conf.d"]],
  }

  case $additional_lib {
    ''      : {
      debug('no additional libraries.')
    }
    default : {
      file { "${ganglia::params::metrics_py}/${additional_lib}":
        ensure  => $ensure,
        source  => "puppet:///modules/${additional_lib_source}/${additional_lib}",
        notify  => Service[$ganglia::params::gmond],
        recurse => true,
        force   => true,
      }
    }
  }
}
