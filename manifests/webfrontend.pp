# Writtenby: udo.waechter@uni-osnabrueck.de
#
# _Class:_ ganglia::webfrontend
#
# Install and configure a ganglia metaserver and a webfrontend.
#
# This module was tested with Debian (Etch/Lenny)
#
# _Parameters:_
#
# _Actions:_
#   Installs a metaserver and a ganglia webfrontend.
#
# _Requires:_
#   webserver::apache2 module
#
# _Sample Usage:_
#   +include ganglia::webfrontend+
#
class ganglia::webfrontend (
  $ensure           = 'present',
  $www_dir          = '/usr/share/ganglia-webfrontend',
  $rrdcached_socket = false,
  $auth_system      = 'disabled',
  $strip_domainname = true,
  $metriccols       = '3',
  $hostcols         = '4',
  $memcached        = false) {
  include 'ganglia::params'

  File {
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['ganglia-webfrontend']
  }

  file {
    '/etc/ganglia-webfrontend/conf.php':
      content => template('ganglia/web_conf_default.php.erb');

    [
      '/var/lib/ganglia-web/dwoo',
      '/var/lib/ganglia-web/conf']:
      recurse => true;
  }

  package { ['ganglia-webfrontend']: ensure => $ensure, }
  # collect the meta configs for this host.
  File <<| tag == 'ganglia_metad_all' |>> {
    notify => Exec['generate-metadconf'],
  }

  # # install the cleanupscript
  file { '/usr/local/sbin/ganglia_rrdcleanup.sh':
    source => 'puppet:///modules/ganglia/rrdcleanup.sh',
    owner  => 'root',
    mode   => '0700',
  }

  cron { 'ganglia_rrdcleanup.sh':
    command  => '/usr/local/sbin/ganglia_rrdcleanup.sh',
    minute   => '20',
    hour     => '3',
    monthday => '*/10',
    user     => 'root',
    require  => File['/usr/local/sbin/ganglia_rrdcleanup.sh'],
  }
}
