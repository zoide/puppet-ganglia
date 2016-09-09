class ganglia::metric::rabbitmq (
  $ensure = 'present') {
  ganglia::module::python_git { 'rabbit':
    pyconf       => 'rabbitmq',
    creates      => 'rabbitmq.py',
    conf_replace => {
      'pattern'     => 'value = "/,vhost1,vhost2"',
      'replacement' => 'value = "/"',
    }
  }
}
