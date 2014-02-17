require 'puppet/provider/package'

Puppet::Type.type(:package).provide(:chocolatey, :parent => Puppet::Provider::Package) do
  desc "Package management using Chocolatey on Windows"

  confine    :operatingsystem => :windows

  has_feature :installable, :install_options
  has_feature :uninstallable
  has_feature :upgradeable
  has_feature :versionable

  commands :chocolatey => "#{ENV['ChocolateyInstall'] || 'C:\Chocolatey'}\\chocolateyInstall\\chocolatey.cmd"

 def print()
   notice("The value is: '${name}'")
 end

  def package_name
    @resource[:name][/\A\S*/]
  end

  def install_options
    Array(@resource[:install_options]).flatten.compact
  end

  def install
    Puppet.notice "Installing #{@resource[:name]}"
    case should = @resource[:ensure]
      when true, false, Symbol then options = []
      else                          options = '-version', should
    end
    options << '-source' << @resource[:source] if @resource[:source]
    options << install_options                 if install_options.any?
    chocolatey :install, package_name, *options
  end

  def uninstall
    Puppet.notice "Uninstalling #{@resource[:name]}"
    chocolatey :uninstall, package_name
  end

  def update
    Puppet.notice "Updating #{@resource[:name]}"
    options = []
    options << '-source' << @resource[:source] if @resource[:source]
    options << install_options                 if install_options.any?
    chocolatey :update, package_name, *options
  end

  def query
    Puppet.debug "Querying #{@resource[:name]}"
    self.class.instances.each do |provider_chocolatey|
      return provider_chocolatey.properties if !package_name.casecmp(provider_chocolatey.name)
    end
    return nil
  end

  def self.listcmd
    [command(:chocolatey), "list", "-lo"]
  end

  def self.instances
    packages = []

    begin
      execpipe(listcmd()) do |process|
        process.each_line do |line|
          line.chomp!
          if line.empty? or line.match(/Reading environment variables.*/); next; end
          values = line.split(' ')
          packages << new({ :name => values[0], :ensure => values[1], :provider => self.name })
        end
      end
    rescue Puppet::ExecutionFailure
      return nil
    end
    packages
  end

  def latestcmd
    [command(:chocolatey), ' version ' + package_name + ' | findstr /R "latest" | findstr /V "latestCompare" ']
  end

  def latest
    packages = []

    begin
      output = execpipe(latestcmd()) do |process|

        process.each_line do |line|
          line.chomp!
          if line.empty?; next; end
          # Example: ( latest        : 2013.08.19.155043 )
          values = line.split(':').collect(&:strip).delete_if(&:empty?)
          return values[1]
        end
      end
    rescue Puppet::ExecutionFailure
      return nil
    end
    packages
  end

end
