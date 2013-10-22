puppet-chocolatey
=================

Installs Chocolatey and provider for packages

Description
-----------

Yet another [Puppet](http://docs.puppetlabs.com) module for [Chocolatey](http://chocolatey.org).

Installation
------------

Via [puppet module](http://docs.puppetlabs.com/puppet/2.7/reference/modules_installing.html#installing-modules-1):

```bash
$ puppet module install xxxx
```

Via [librarian-puppet](https://github.com/rodjek/librarian-puppet), by adding the following line to your Puppetfile:

```
mod 'chocolatey', :git =>  'https://github.com/gildas/puppet-chocolatey.git'
```

Usage
-----

First you need to make sure Chocolatey is properly installed by including its class:

```puppet
include chocolatey
```

Or, with some parameters:

```puppet
class {chocolatey:
}
```

