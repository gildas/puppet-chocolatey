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

  exec {'install-chocolatey':
    command  => "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))",
    creates  => 'C:/chocolatey',
    provider => powershell,
  }

  # Installs packages from hiera
  $packages = hiera_array('packages', [])
  if (!empty($packages))
  {
    notice(" Checking packages: ${packages}")
    package {$packages:
      ensure   => installed,
      provider => chocolatey,
      require  => Exec['install-chocolatey'],
    }
  }
}
