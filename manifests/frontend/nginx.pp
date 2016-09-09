class ganglia::frontend::nginx (
  $ensure            = 'present',
  $rrdcached_socket  = 'unix:/var/run/rrdcached.sock',
  $memcached_servers = 'localhost:11211',
  $ssl               = false,
  $ssl_only          = false,
  $vhost             = $::fqdn) {
  class { 'ganglia::metaserver':
    ensure           => $ensure,
    rrdcached_socket => $rrdcached_socket,
    memcached        => $memcached_servers,
    server_threads   => '12',
  }

  class { 'ganglia::webfrontend':
    ensure           => $ensure,
    rrdcached_socket => $rrdcached_socket,
    memcached        => $memcached_servers,
  }

  package { ['php5-xcache']: }

  service { 'apache2':
    ensure => stopped,
    enable => false,
  }

  class { 'rrdcached':
    listen           => $rrdcached_socket,
    gid              => 'ganglia',
    mode             => '0666',
    jump_dir         => '/var/lib/ganglia/rrds',
    always_flush     => true,
    enable_corefiles => false,
    restrict_writes  => true,
    write_threads    => '12',
    maxwait          => '300'
  }

  $www_root = '/usr/share/ganglia-webfrontend'

  class { ['php::extension::gd', 'php::extension::imagick', 'php::fpm']: }

  php::fpm::pool { 'www':
    listen                  => '127.0.0.1:9000',
    pm_start_servers        => 2 * $::physicalprocessorcount,
    pm_min_spare_servers    => 2 * $::physicalprocessorcount,
    pm_max_spare_servers    => 2 * $::physicalprocessorcount,
    pm_status_path          => '/status',
    pm_max_requests         => '10000',
    chdir                   => $www_root,
    catch_workers_output    => 'yes',
    request_slowlog_timeout => '10s',
    pm_max_children         => 100 * $::physicalprocessorcount,
  }

  if $ssl == true {
    Nginx::Resource::Vhost {
      rewrite_to_https => true, }
  }

  nginx::resource::vhost { $vhost:
    www_root    => $www_root,
    ssl         => $ssl,
    index_files => ['index.php'],
  }

  nginx::resource::location { "${vhost}_root":
    ensure              => present,
    ssl                 => $ssl,
    ssl_only            => $ssl_only,
    vhost               => $vhost,
    www_root            => $www_root,
    location            => '~ \.php$',
    index_files         => ['index.php'],
    fastcgi             => '127.0.0.1:9000',
    fastcgi_script      => undef,
    proxy_set_header    => [],
    location_cfg_append => {
      fastcgi_connect_timeout => '3m',
      fastcgi_read_timeout    => '3m',
      fastcgi_send_timeout    => '3m'
    }
  }
}
