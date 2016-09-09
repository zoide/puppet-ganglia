class ganglia::metric::nfs (
  $ensure = 'present') {
  ganglia::module::python_git { 'nfsstats': ensure => $pres }
}
