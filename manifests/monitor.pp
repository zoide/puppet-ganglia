# Writtenby: udo.waechter@uni-osnabrueck.de
#
# _Class:_ ganglia::monitor
#
# Enables and installs the monitor daemond gmon.
#
# This module was tested with Debian (Etch/Lenny), Ubuntu (Hardy/Intrepid),
# Mac OS X Leopard and FreeBSD 7.
#
# _Parameters:_
#
# _Actions:_
#   Installs the ganglia-monitor package and configures it.
#
# _Requires:_
#
# _Sample Usage:_
#   +include ganglia::monitor+
#
class ganglia::monitor (
  $ensure      = 'present',
  $cluster     = $::domain,
  $company     = $::company,
  $latlong     = $::network_location,
  $url         = $::documentation_url,
  $location    = '',
  $deaf        = 'yes',
  $multicast   = false,
  $bindaddress = $::ipaddress,
  $port        = '8650',
  $metaserver  = "gmetad.${::domain}") {
  include 'ganglia::params'
  $includes = true

  class { 'ganglia::monitor::base': ensure => $ensure }
  $ganglia_monitor_conf = "${ganglia::params::mconf_dir}/gmond.conf"
  $package = $kernel ? {
    'FreeBSD' => 'ganglia-monitor-core',
    'Darwin'  => 'ganglia',
    default   => 'ganglia-monitor'
  }
  $pathprefix = $kernel ? {
    'FreeBSD' => '/usr/local',
    'Darwin'  => '/opt/local',
    default   => '/usr'
  }
  $pack_present = $ensure ? {
    'present' => 'latest',
    default   => $ensure,
  }

  File {
    ensure  => $ensure,
    owner   => $ganglia::params::user,
    group   => $ganglia::params::group,
    mode    => '0700',
    force   => true,
    recurse => true,
  }

  package { $package:
    before => Service[$ganglia::params::gmond],
    ensure => $pack_present,
  }

  case $::kernel {
    'Darwin' : {
      darwin_firewall { 'any':
        port   => '8649',
        ensure => $ensure,
      }

      replace { '/opt/local/etc/LaunchDaemon/org.macports.ganglia/org.macports.ganglia.plist':
        pattern     => '/opt/local/var/log/',
        replacement => '/var/log/',
        notify      => Service[$ganglia::params::gmond],
      }
    }
    'Linux'  : {
      package { ['ganglia-monitor-python', 'ganglia-modules-linux']: ensure => $pack_present, }

      exec { 'disable-all-python-plugins-initially':
        command     => '/usr/bin/find -type f -iname "*pyconf" -exec rename \'s/.pyconf$/.pyconf.disabled/\' {} \;',
        cwd         => $ganglia::params::conf_d,
        refreshonly => true,
        subscribe   => Package['ganglia-monitor-python'],
      }
      $name_real = "gmond"

      file { "/etc/init.d/${ganglia::params::gmond}":
        ensure  => $ensure,
        content => template('ganglia/gmond-init.d.erb'),
        mode    => '0755',
      }
    }
  }
  # ### configure the service daemon
  $enabled = $ensure ? {
    'absent' => 'false',
    default  => 'true'
  }

  if $enabled == 'true' {
    Service[$ganglia::params::gmond] {
      require => Package[$package], }

    File {
      notify => Service[$ganglia::params::gmond], }
  }

  service { $ganglia::params::gmond:
    ensure    => $enabled,
    enable    => $enabled,
    hasstatus => false,
    pattern   => '/usr/sbin/gmond',
  }

  file {
    $ganglia::params::mconf_dir:
      ensure => $ensure ? {
        'present' => 'directory',
        default   => $ensure,
      } ;

    $ganglia::params::conf_d:
      ensure  => $ensure ? {
        'present' => 'directory',
        default   => $ensure,
      },
      require => File[$ganglia::params::mconf_dir];
  }
  debug("${::fqdn} should ${package} have ${ensure} / enable: ${enabled} / conf: ${ganglia_monitor_conf}")

  if $ensure == 'present' {
    debug("${::fqdn}=$ensure, metaserver=${metaserver}, cluster=${cluster}, port=${port},")

    file {
      $ganglia_monitor_conf:
        content => template('ganglia/ganglia-monitor-conf.erb'),
        require => [File[$ganglia::params::mconf_dir], Package[$package]];

      "${ganglia::params::mconf_dir}/conf.d/0000-cluster.conf":
        content => template('ganglia/gmond-cluster.conf.erb'),
        require => File[$ganglia::params::conf_d];

      "${ganglia::params::mconf_dir}/conf.d/collection_groups.conf":
        source  => 'puppet:///modules/ganglia/conf.d/collection_groups.conf',
        require => File[$ganglia::params::conf_d];

      "${ganglia::params::mconf_dir}/conf.d/modules.conf":
        content => template('ganglia/gmond-modules.conf.erb'),
        require => File[$ganglia::params::conf_d];
    }

    #    @@common::line { "collect: ${::fqdn} ${cluster} ${port}":
    #      tag    => 'collect_gmond',
    #      file   => "${ganglia::params::metacollects}/collect_${cluster}",
    #      line   => "#${cluster};${fqdn}:${port}",
    #      notify => Exec['generate-metadconf'],
    #    }

    Ganglia::Send {
      metaserver  => $metaserver,
      multicast   => $multicast,
      require     => File[$ganglia::params::conf_d],
      bindaddress => $bindaddress,
    }

    ganglia::send { "${name} *:${port}": port => $port, }

    if defined(Class['monit']) {
      # # monitoring
      monit::process { 'gmond':
        start  => '/etc/init.d/ganglia-monitor start',
        stop   => '/etc/init.d/ganglia-monitor stop',
        ensure => $ensure,
      }
    }

    # #Clone the python-modules-repo:
    Git::Clone {
      localtree => "${::puppet_vardir}/exported", }

    git::clone {
      'gmond-python-modules-git':
        source => 'https://github.com/ganglia/gmond_python_modules.git';

      'gmond-gmetric-modules-git':
        source => 'https://github.com/ganglia/gmetric.git';
    }

    #    Git::Pull {
    #      localtree => '/var/lib/puppet/exported',
    #      reset     => false,
    #      clean     => false,
    #      schedule  => 'weekly',
    #    }
    #
    #    git::pull {
    #      'update-gmond-python-modules-git':
    #        real_name => 'gmond-python-modules-git';
    #
    #      'update-gmond-gmetric-modules-git':
    #        real_name => 'gmond-gmetric-modules-git';
    #    }
  }

}

