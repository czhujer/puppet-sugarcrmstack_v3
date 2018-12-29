require 'beaker-rspec'
require 'beaker/puppet_install_helper'
require 'beaker/module_install_helper'

run_puppet_install_helper

# fix module name
hosts.each do |host|
  on(host, "cd /etc/puppetlabs/code/modules && ln -s sugarcrmstack_v3 sugarcrmstack")
end

install_module

# debug module status
# hosts.each do |host|
#  on(host, "ls -lh /etc/puppetlabs/code/modules/sugarcrmstack/*")
# end

# install_module_dependencies

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # some fixes
  hosts.each do |host|
    if host[:platform] =~ %r{el-6-x86_64} && host[:hypervisor] =~ %r{docker}
      on(host, "sed -i '/nodocs/d' /etc/yum.conf")
    end
    # if host[:platform] =~ %r{el-7-x86_64} && host[:hypervisor] =~ %r{docker}
    #  on(host, "sed -i '/nodocs/d' /etc/yum.conf")
    # end
  end

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    # puppet_module_install(:source => proj_root, :module_name => 'sugarcrmstack')
    hosts.each do |host|
      on host, puppet('module', 'install', 'puppetlabs-stdlib', '-v', '4.25.1'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'puppetlabs-inifile', '-v', '2.4.0'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'puppetlabs-apache'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'puppetlabs-concat'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'puppetlabs-mysql'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'puppet-cron'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'thias-php'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'puppetlabs-firewall'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'puppetlabs-vcsrepo'), { :acceptable_exit_codes => [0,1] }
      on(host, 'cd /etc/puppetlabs/code/modules && git clone https://github.com/SugarFactory/puppet-composer.git composer'), { :acceptable_exit_codes => [0] }
    end
  end
end
