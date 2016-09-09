class ganglia::metric::diskstat (
  $ensure = 'present') {
  $disk_str = gsub($::blockdevices, ',', ' ')

  ganglia::module::python { 'diskstat':
    conf_replace => {
      'pattern'     => 'value.*=.*\'\'',
      'replacement' => "value = '${disk_str}'"
    }
    ,
  }
}
