# Private class that manages Windows envioronment variables and/or machine.config proxy settings
#
class proxy::windows::config (
  String $server                 = $proxy::server_address,
  String $exclude                = $proxy::exclude,
  Boolean $manage_env_vars       = $proxy::manage_env_vars,
  Boolean $manage_machine_config = $proxy::manage_machine_config,
  String $dotnet_folder          = $proxy::dotnet_folder,
  $bypass_list                   = hiera_array('proxy::proxy_bypass_list', { })
) {

  $ensure                  = empty($server) ? { true  => 'absent', false => 'present' }
  $web_config_fullpath     = "${dotnet_folder}\\web.config"
  $machine_config_fullpath = "${dotnet_folder}\\machine.config"

  if ($manage_env_vars) {
    windows_env { 'http_proxy':
      ensure    => $ensure,
      variable  => 'http_proxy',
      value     => $server,
      mergemode => clobber,
    }

    windows_env { 'https_proxy':
      ensure    => $ensure,
      variable  => 'https_proxy',
      value     => $server,
      mergemode => clobber,
    }

    if !empty($exclude) {
      windows_env { 'no_proxy':
        ensure    => $ensure,
        value     => $exclude,
        mergemode => clobber,
      }
    }
  }

  if ($manage_machine_config) {
    exec { 'Remove web.config default proxy settings' :
      command   => "\$xmlFile = '${web_config_fullpath}';[xml]\$xml = Get-Content \$xmlFile;[void]\$xml.configuration.\"system.net\".RemoveChild(\$xml.configuration.\"system.net\".defaultProxy);\$xml.Save(\$xmlFile)",
      onlyif    => "[xml]\$xml = Get-Content '${web_config_fullpath}'; if (\$xml.configuration.\"system.net\".defaultProxy -eq \$null) { exit 1 } else { exit 0 }",
      logoutput => true,
      provider  => powershell,
    }

    exec { 'Add system.net section to machine.config' :
      command   => "\$xmlFile = '${machine_config_fullpath}';[xml]\$xml = Get-Content \$xmlFile;\$newElement=\$xml.CreateElement('system.net');[void]\$xml.configuration.AppendChild(\$newElement);\$xml.Save(\$xmlFile)",
      onlyif    => "[xml]\$xml = Get-Content '${machine_config_fullpath}'; if (\$xml.configuration.\"system.net\" -ne \$null) { exit 1 } else { exit 0 }",
      logoutput => true,
      provider  => powershell,
    }

    if (!empty($server)) {
      exec { 'Add defaultProxy element' :
        command   => "\$xmlFile = '${machine_config_fullpath}';[xml]\$xml = Get-Content \$xmlFile;\$newElement=\$xml.CreateElement('defaultProxy');\$node=\$xml.SelectNodes('/configuration/system.net').AppendChild(\$newElement) | Out-Null;\$xml.Save(\$xmlFile)",
        onlyif    => "[xml]\$xml = Get-Content '${machine_config_fullpath}'; if (\$xml.configuration.\"system.net\".defaultProxy -ne \$null) { exit 1 } else { exit 0 }",
        logoutput => true,
        provider  => powershell,
      }

      exec { 'Add proxy element' :
        command   => "\$xmlFile = '${machine_config_fullpath}';[xml]\$xml = Get-Content \$xmlFile;\$newElement=\$xml.CreateElement('proxy');\$newElement.SetAttribute('bypassonlocal', 'true');\$node=\$xml.SelectNodes('/configuration/system.net/defaultProxy').AppendChild(\$newElement) | Out-Null;\$xml.Save(\$xmlFile)",
        onlyif    => "[xml]\$xml = Get-Content '${machine_config_fullpath}'; if (\$xml.configuration.\"system.net\".defaultProxy.proxy -ne \$null) { exit 1 } else { exit 0 }",
        logoutput => true,
        provider  => powershell,
      }

      exec { 'Update default proxy address attribute' :
        command   => "\$xmlFile = '${machine_config_fullpath}';[xml]\$xml = Get-Content \$xmlFile;\$xml.SelectNodes('/configuration/system.net/defaultProxy/proxy').SetAttribute(\"proxyaddress\", \"${server}\");\$xml.Save(\$xmlFile)",
        onlyif    => "[xml]\$xml = Get-Content '${machine_config_fullpath}'; if (\$xml.configuration.\"system.net\".defaultProxy.proxy.proxyaddress -eq '${server}') { exit 1 } else { exit 0 }",
        logoutput => true,
        provider  => powershell,
      }

      exec { 'Add bypasslist element' :
        command   => "\$xmlFile = '${machine_config_fullpath}';[xml]\$xml = Get-Content \$xmlFile;\$newElement=\$xml.CreateElement('bypasslist');\$node=\$xml.SelectNodes('/configuration/system.net/defaultProxy').AppendChild(\$newElement) | Out-Null;\$xml.Save(\$xmlFile)",
        onlyif    => "[xml]\$xml = Get-Content '${machine_config_fullpath}'; if (\$xml.configuration.\"system.net\".defaultProxy.bypasslist -ne \$null) { exit 1 } else { exit 0 }",
        logoutput => true,
        provider  => powershell,
      }

      $bypass_list.each | Hash $bypassitem | {
          case $bypassitem[ensure] {
            /^(present)$/ : {
              exec { "add addresses to proxy bypass list: ${bypassitem[address]}" :
                command   => "\$xmlFile = '${machine_config_fullpath}';[xml]\$xml = Get-Content \$xmlFile;\$newElement=\$xml.CreateElement('add');\$newElement.SetAttribute('address', '${bypassitem[address]}');\$node=\$xml.SelectNodes('/configuration/system.net/defaultProxy/bypasslist').AppendChild(\$newElement) | Out-Null;\$xml.Save(\$xmlFile)",
                onlyif    => "[xml]\$xml = Get-Content '${machine_config_fullpath}'; if (\$xml.selectSingleNode(\"/configuration/system.net/defaultProxy/bypasslist/add[@address='${bypassitem[address]}']\") -ne \$null) { exit 1 } else { exit 0 }",
                logoutput => true,
                provider  => powershell,
              }
            }
            /^(absent)$/  : {
              exec { "remove address from proxy bypass list: ${bypassitem[address]}" :
                command   => "\$xmlFile = '${machine_config_fullpath}';[xml]\$xml = Get-Content \$xmlFile;\$node = \$xml.selectSingleNode(\"/configuration/system.net/defaultProxy/bypasslist/add[@address='${bypassitem[address]}']\");\$node.ParentNode.RemoveChild(\$node) | Out-Null;\$xml.Save(\$xmlFile)",
                onlyif    => "[xml]\$xml = Get-Content '${machine_config_fullpath}'; if (\$xml.selectSingleNode(\"/configuration/system.net/defaultProxy/bypasslist/add[@address='${bypassitem[address]}']\") -eq \$null) { exit 1 } else { exit 0 }",
                logoutput => true,
                provider  => powershell,
              }
            }
            default       : { fail("the value ensure ensure must be present or absent not: ${ensure}") }
          }
        }
    } else {
      exec { "remove proxy from machine.config" :
        command   => "\$xmlFile = '${machine_config_fullpath}';[xml]\$xml = Get-Content \$xmlFile;\$node = \$xml.selectSingleNode(\"/configuration/system.net/defaultProxy\");\$node.ParentNode.RemoveChild(\$node) | Out-Null;\$xml.Save(\$xmlFile)",
        onlyif    => "[xml]\$xml = Get-Content '${machine_config_fullpath}'; if (\$xml.selectSingleNode(\"/configuration/system.net/defaultProxy\") -eq \$null) { exit 1 } else { exit 0 }",
        logoutput => true,
        provider  => powershell,
      }
    }
  }
}
