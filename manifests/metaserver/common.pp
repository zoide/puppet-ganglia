# Writtenby: udo.waechter@uni-osnabrueck.de
#
# _Class:_ ganglia::metaserver::common
#
# Common class for Metaserver and webfrontend class. Do not use directly
#
# This module was tested with Debian (Etch/Lenny)
#
# _Parameters:_
#
# _Actions:_
#   Installs the metaserver.
#
# _Requires:_
#
# _Sample Usage:_
#
class ganglia::metaserver::common ($ensure = 'present', $server_threads = '4', $rrdcached_socket = false, $memcached = false) {
  include 'ganglia::params'
  $fqdn_r = $::fqdn
  $ganglia_metaconf = '/etc/ganglia/gmetad.conf'
  $package = 'gmetad'
  $fpresent = $ensure ? {
    'absent' => 'absent',
    default  => 'directory',
  }

  $pack_ensure = $ensure ? {
    'present' => 'present', # 'latest',
    default   => $ensure,
  }

  file { $ganglia::params::metacollects:
    ensure  => $fpresent,
    owner   => 'root',
    mode    => '0700',
    force   => true,
    backup  => false,
    recurse => true,
  }

  file { "${ganglia::params::metacollects}/../generate-gmetad.conf.sh":
    source => 'puppet:///modules/ganglia/generate-gmetad.conf.sh',
    mode   => '0700',
    ensure => 'absent',
    notify => Exec['generate-metadconf']
  }

  package { $package:
    ensure => $pack_ensure,
    before => [Service['gmetad'], Exec['generate-metadconf']],
  }

  $run = $ensure ? {
    'absent' => false,
    default  => true
  }
  debug("${fqdn_r} should be \"${ensure}\"")

  file { '/etc/init.d/gmetad':
    content => template('ganglia/gmetad.init.erb'),
    require => Package[$package],
    before  => Service['gmetad'],
    notify  => Service['gmetad'],
    mode    => '0755',
  }

  service { 'gmetad':
    ensure    => $run,
    enable    => $run,
    subscribe => Exec['generate-metadconf'],
    pattern   => '/sbin/gmetad',
    hasstatus => false,
    require   => Package[$package],
  }

  file { "${ganglia::params::metacollects}/0000-gmetad.conf":
    content => template('ganglia/gmetad.conf.erb'),
    ensure  => $ensure,
    notify  => Exec['generate-metadconf'],
    require => File[$ganglia::params::metacollects],
  }

  if $ensure == 'present' {
    # ## generate the configuration file
    exec { 'generate-metadconf':
      #command     => "${ganglia::params::metacollects}/../generate-gmetad.conf.sh ${ganglia::params::metacollects} >${ganglia_metaconf}",
      command     => "cat ${ganglia::params::metacollects}/* >${ganglia_metaconf}",
      refreshonly => true,
      onlyif      => "test -f ${ganglia_metaconf}",
    }
  } else {
    exec { 'generate-metadconf': command => '/bin/echo "no metaserver here"', }
  }

  File['/var/lib/ganglia/rrds'] {
    recurse => true, }

  file { ['/var/lib/ganglia', '/var/lib/ganglia/rrds']:
    ensure => $fpresent,
    backup => false,
    owner  => $ganglia::params::user,
    group  => $ganglia::params::group,
    mode   => '0775',
  }

  if defined(Class['monit']) {
    monit::process { 'gmetad': ensure => $ensure }
  }
}
