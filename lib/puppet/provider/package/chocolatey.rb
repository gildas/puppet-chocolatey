require 'puppet/provider/package'

Puppet::Type.type(:package).provide(:chocolatey, :parent => Puppet::Provider::Package) do
  desc "Package management using Chocolatey on Windows"

  confine    :operatingsystem => :windows

  has_feature :installable, :install_options
  has_feature :uninstallable
  has_feature :upgradeable
  has_feature :versionable

  commands :chocolatey => "#{ENV['ChocolateyInstall'] || 'C:\Chocolatey'}\\chocolateyInstall\\chocolatey.cmd"

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
    begin
      chocolatey :install, package_name, *options
    rescue Puppet::ExecutionFailure
      Puppet.error "Package #{@resource[:name]} Install failed: #{$!}"
      nil
    end
  end

  def uninstall
    Puppet.notice "Uninstalling #{@resource[:name]}"
    begin
      chocolatey :uninstall, package_name
    rescue Puppet::ExecutionFailure
      Puppet.error "Package #{@resource[:name]} Uninstall failed: #{$!}"
      nil
    end
  end

  def update
    Puppet.notice "Updating #{@resource[:name]}"
    options = []
    options << '-source' << @resource[:source] if @resource[:source]
    options << install_options                 if install_options.any?
    begin
      chocolatey :update, package_name, *options
    rescue Puppet::ExecutionFailure
      Puppet.error "Package #{@resource[:name]} Update failed: #{$!}"
      nil
    end
  end

  def query
    Puppet.debug "Querying #{@resource[:name]}"
    begin
      execpipe([command(:chocolatey), :list, "-localonly", package_name]) do |process|
        process.each_line do |line|
          line.chomp!
          next if line.empty? or line =~ /Reading environment variables/
          next if line !~ /^(#{package_name})\s+(.*)/i
          Puppet.debug "  #{$1} is at #{$2}"
          return { :name => $1, :ensure => $2, :provider => 'chocolatey' }
        end
      end
      Puppet.debug "  #{@resource[:name]} not installed"
      nil
    rescue Puppet::ExecutionFailure
      Puppet.error "Package #{@resource[:name]} Query failed: #{$!}"
      nil
    end
  end

  def latest
    Puppet.debug "Querying latest for #{@resource[:name]}"
    begin
      execpipe([command(:chocolatey), :version, package_name]) do |process|
        process.each_line do |line|
          line.chomp!
          next if line.empty? or line =~ /Reading environment variables/
          next if line !~ /^latest\s+:\s(.*)/i
          Puppet.debug "  Latest version for #{@resource[:name]}: #{$1}"
          return $1
        end
      end
      nil
    rescue Puppet::ExecutionFailure
      Puppet.error "Package #{@resource[:name]} Query Latest failed: #{$!}"
      nil
    end
  end

  def self.instances
    Puppet.debug "Listing currently installed packages"
    packages = []
    begin
      execpipe([command(:chocolatey), :list, '-localonly']) do |process|
        process.each_line do |line|
          line.chomp!
          next if line.empty? or line =~ /Reading environment variables/
          info = line.strip.split(' ')
          Puppet.debug "  Package #{info[0]} is at version: #{info[1]}."
          packages << new({ :name => info[0], :ensure => info[1], :provider => 'chocolatey' })
        end
      end
      packages
    rescue Puppet::ExecutionFailure
      Puppet.error "Instances failed: #{$!}"
      nil
    end
  end

end
