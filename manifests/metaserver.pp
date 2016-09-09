# Writtenby: udo.waechter@uni-osnabrueck.de
#
# _Class:_ ganglia::metaserver
#
# Install and configure a ganglia metaserver
#
# This module was tested with Debian (Etch/Lenny)
#
# _Parameters:_
#
# _Actions:_
#   Installs a metaserver.
#
# _Requires:_
#
# _Sample Usage:_
#   +include ganglia::metaserver+
class ganglia::metaserver (
  $ensure           = 'present',
  $server_threads   = '4',
  $rrdcached_socket = false,
  $memcached        = false) {
  tag('ganglia')
  include 'ganglia::params'
  $fqdn_r = downcase($fqdn)

  class { 'ganglia::metaserver::common':
    ensure           => $ensure,
    rrdcached_socket => $rrdcached_socket,
    memcached        => $memcached,
    server_threads   => $server_threads,
  }

  if $ensure == 'present' {
    # collect the meta configs for this host.
    Common::Line <<| tag == 'collect_gmond' |>> {
    }
  }

}

