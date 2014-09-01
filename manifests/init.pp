# == Class: chocolatey
#
# Full description of class chocolatey here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if it
#   has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should not be used in preference to class parameters  as of
#   Puppet 2.6.)
#
# === Examples
#
#  class { chocolatey:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ]
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2013 Your name here, unless otherwise noted.
#
class chocolatey
{
  if ($::operatingsystem != 'Windows')
  {
    err('This Module works on Windows only!')
    fail("Unsupported OS: ${::operatingsystem}")
  }

  # We do not want to copy Unix modes to Windows, it tends to render files unaccessible
  File { source_permissions => ignore }

  file {"C:/Windows/TEMP/chocolatey":
    ensure   => directory,
    provider => windows,
  }

  $dotnet_source  = 'http://download.microsoft.com/download/b/a/4/ba4a7e71-2906-4b2d-a0e1-80cf16844f5f/dotnetfx45_full_x86_x64.exe'
  $dotnet_install = 'dotNetFx45_Full_x86_x64.exe'

  exec {'chocolatey-download-dotnet-4.5':
    command  => "((new-object net.webclient).DownloadFile('${dotnet_source}','C:/Windows/TEMP/chocolatey/${dotnet_install}'))",
    creates  => "C:/Windows/TEMP/chocolatey/${dotnet_install}",
    provider => powershell,
    require  => File["C:/Windows/TEMP/chocolatey"],
  }

  exec {'chocolatey-install-dotnet-4.5':
    command  => "C:/Windows/TEMP/chocolatey/${dotnet_install} /q /norestart /log C:\\Windows\\Logs\\install-dotnet-4.5.log",
    onlyif   => "if (Get-Item C:\Windows\Microsoft.NET\Framework\v4.0.30319 -ErrorAction Ignore) { exit 1 }",
    provider => powershell,
    require  => Exec['chocolatey-download-dotnet-4.5'],
    notify   => Reboot['after'],
  }

# Powershell 3.0
# http://download.microsoft.com/download/E/7/6/E76850B8-DA6E-4FF5-8CCE-A24FC513FD16/Windows6.1-KB2506143-x64.msu

# Powershell 4.0
# http://download.microsoft.com/download/3/D/6/3D61D262-8549-4769-A660-230B67E15B25/Windows6.1-KB2819745-x64-MultiPkg.msu

  $chocolatey_root = 'C:\ProgramData\Chocolatey'

  exec {'chocolatey-install':
    command  => "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))",
    creates  => 'C:/ProgramData/chocolatey/bin/chocolatey.exe',
    provider => powershell,
    require  => Exec['chocolatey-install-dotnet-4.5'],
  }

  exec {'addvar-chocolateyinstall':
    command => 'setx ChocolateyInstall C:\ProgramData\chocolatey',
    unless  => 'reg query "HKCU\Environment" /v ChocolateyInstall',
    path    => [ 'C:/windows/sysnative', 'C:/windows/system32' ],
    require => Exec['install-chocolatey'],
  }

  # Before:
  # setx PATH "%SYSTEMROOT%\system32;%SYSTEMROOT%;%SYSTEMROOT%\system32\Wbem;%SYSTEMROOT%\system32\WindowsPowerShell\v1.0;%ProgramFiles(x86)%\Puppet Labs\Puppet\bin" /M
  # After:
  # setx PATH "%SYSTEMROOT%\system32;%SYSTEMROOT%;%SYSTEMROOT%\system32\Wbem;%SYSTEMROOT%\Wsystem32\indowsPowerShell\v1.0;%ProgramFiles(x86)%\Puppet Labs\Puppet\bin;C:\Chocolatey\bin" /M
  # TODO: We cannot use setx PATH "%PATH%...." since %PATH$ in puppet's environment is minimal.
  # So using it will destroy the standard PATH.
  # I should get stuff from https://github.com/badgerious/puppet-windows-env
  #exec {'chocolatey-environment-path-config':
  #  command => "setx PATH \"%PATH%;C:\\Chocolatey\\bin\" /M",
  #  unless  => "reg.exe query \"HKLM\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment\" /v PATH | findstr /L /C:\"Chocolatey\"",
  #  path    => [ 'C:/windows/sysnative', 'C:/windows/system32' ],
  #  require => Exec['chocolatey-install'],
  #}
  #exec {'addsyspath-chocolatey':
  #  command => 'setx /M path C:\chocolatey\bin',
  #  unless  => 'reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path | findstr Chocolatey',
  #  path    => [ 'C:/windows/sysnative', 'C:/windows/system32' ],
  #  require => Exec['install-chocolatey'],
  #}

  # Installs packages from hiera
  $packages = hiera_hash('packages', {})
  if (!empty($packages))
  {
    notice(" Checking packages: ${packages}")
    $package_defaults = {
      ensure   => installed,
      provider => chocolatey,
      require  => Exec['chocolatey-install'],
    }
    create_resources(package, $packages, $package_defaults)
  }
}
