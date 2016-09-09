# Writtenby: udo.waechter@uni-osnabrueck.de
#
# _Class:_ ganglia::metaserver::tmpfs
#
# Use tmpfs to store rrd metrics
#
# This module was tested with Debian (Etch/Lenny)
#
# _Parameters:_
#
# _Actions:_
#   Installs a metaserver and setups tmpfs.
#
# _Requires:_
#
# _Sample Usage:_
#   +include ganglia::metaserver::tmpfs+

class ganglia::metaserver::tmpfs (
  $ensure        = 'present',
  $ganglia_tmpfs = '/var/lib/ganglia/rrds') {
  # collect the meta configs for this host.
  include 'ganglia::params'

  if $ensure == 'present' {
    File <<| tag == "ganglia_gmond_${::domain}" |>>
  }

  if $ganglia_tmpfs != '/var/lib/ganglia/rrds' {
    notice("${::hostname} ganglia::tmpfs ensure: ${ensure}, tmpfs: ${ganglia_tmpfs}"
    )

    cron { 'ganglia-tmpfs':
      ensure  => $ensure,
      minute  => '*/30',
      command => "if [ -d ${ganglia_tmpfs}/rrds/__SummaryInfo__ ]; then rsync -aczH ${ganglia_tmpfs}/rrds/ /var/lib/ganglia/rrds/; fi 2>&1",
      user    => $ganglia::params::user,
    }
    $ens_mount = $ensure ? {
      'absent' => 'absent',
      default  => 'mounted'
    }

    mount { $ganglia_tmpfs:
      ensure  => $ens_mount,
      device  => 'none',
      fstype  => 'tmpfs',
      dump    => 0,
      pass    => 0,
      options => 'size=1024M,mode=755,uid=ganglia,gid=ganglia',
      before  => Service['gmetad'],
    }
  }
}
