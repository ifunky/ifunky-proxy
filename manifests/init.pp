# Manages proxy settings on Linux and Windows servers.  On Linux servers by default it will add environment
# varaibles to /etc/environment.
#
# @example when declaring the proxy class
#   class { 'proxy':
#     $server_address => 'http://my-proxy.net:3128',
#     $exclude        => 'localhost, 169.254.169.254',
#    }
#
# @param server_address Required. Proxy server addfress i.e. http://my-proxy.net:3128
# @param exclude Options.  List of addresses to exclude from accesing via the proxy
# @param environment_file Required.  Linux - File where the proxy environment vars will be written
# @param manage_machine_config Required.  Windows - true if the machine.config file will be managed
# @param manage_env_vars Required.  Windows - Should this module manage the environment variables
#
class proxy (
  String $server_address         = undef,
  String $exclude                = '',
  String $environment_file       = $proxy::params::envionment_file,
  String $dotnet_folder          = $proxy::params::dotnet_folder,
  Boolean $manage_machine_config = true,
  Boolean $manage_env_vars       = true,
) inherits proxy::params {

  unless $server_address =~ /^(http(?:s)?\:\/\/[a-zA-Z0-9]+(?:(?:\.|\-)[a-zA-Z0-9]+)+(?:\:\d+)?(?:\/[\w\-]+)*(?:\/?|\/\w+\.[a-zA-Z]{2,4}(?:\?[\w]+\=[\w\-]+)?)?(?:\&[\w]+\=[\w\-]+)*)$/ {
    fail ('you must enter a proxy url in a valid format i.e. http://proxy.net:3128')
  }

  case $::kernel {
    'Linux':   {
      class{ '::proxy::linux::config':
      }
    }
    'Windows': {
      class{'::proxy::windows::config':
      }
    }
    default:   {
      fail('Unknown OS...Fork and make it better :-)')
    }
  }

}
