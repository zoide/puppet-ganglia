define ganglia::send (
  $port,
  $metaserver,
  $multicast   = false,
  $bindaddress = $::ipaddress,
  $ensure      = 'present') {
  include 'ganglia::params'

  # ## Create the listen statement for this port/host
  file { "${ganglia::params::conf_d}/${port}-send.conf":
    content => template('ganglia/gmond-send.erb'),
    notify  => Service[$ganglia::params::gmond],
    ensure  => $ensure,
  }
}
