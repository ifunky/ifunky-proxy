# Private class for configuring linux servers.
#
#
class proxy::linux::config (
  String $server                 = $proxy::server_address,
  String $exclude                = $proxy::exclude,
) {

  $ensure = empty($server) ? { true  => 'absent', false => 'present' }

  file_line { 'proxy-http':
    ensure => $ensure,
    path   => $proxy::environment_file,
    line   => "export http_proxy=$server",
    match  => '^export\ http_proxy\=',
  }

  file_line { 'proxy-https':
    ensure => $ensure,
    path   => '/etc/environment',
    line   => "export https_proxy=$server",
    match  => '^export\ https_proxy\=',
  }

  file_line { 'proxy-ftp':
    ensure => $ensure,
    path   => '/etc/environment',
    line   => "export ftp_proxy=$server",
    match  => '^export\ ftp_proxy\=',
  }

  if (!empty($exclude)) {
    file_line { 'proxy-exclude':
      ensure => present,
      path   => '/etc/environment',
      line   => "export no_proxy=$exclude",
      match  => '^export\ no_proxy\=',
    }
  }
}
