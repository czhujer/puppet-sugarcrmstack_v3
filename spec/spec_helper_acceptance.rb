require 'beaker-rspec'
require 'beaker/puppet_install_helper'
require 'beaker/module_install_helper'

run_puppet_install_helper

# fix module name
hosts.each do |host|
  on(host, 'cd /etc/puppetlabs/code/modules && ln -s sugarcrmstack_v3 sugarcrmstack')
  on(host, 'mkdir -p /root/scripts')
end

install_module

# debug module status
# hosts.each do |host|
#  on(host, "ls -lh /etc/puppetlabs/code/modules/sugarcrmstack/*")
# end

# install_module_dependencies

RSpec.configure do |c|
  # Project root
  # proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # some fixes
  hosts.each do |host|
    if host[:platform] =~ %r{el-6-x86_64} && host[:hypervisor] =~ %r{docker}
      on(host, "sed -i '/nodocs/d' /etc/yum.conf")
      on(host, 'yum install git python-pip postfix -yq')
    end
    if host[:platform] =~ %r{el-7-x86_64} && host[:hypervisor] =~ %r{docker}
      # on(host, "sed -i '/nodocs/d' /etc/yum.conf")
      on(host, 'yum install git -yq')
    end
  end

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    # puppet_module_install(:source => proj_root, :module_name => 'sugarcrmstack')
    hosts.each do |host|
      on host, puppet('module', 'install', 'puppetlabs-concat', '-v', '4.1.1'), acceptable_exit_codes: [0, 1]
      on host, puppet('module', 'install', 'puppetlabs-stdlib', '-v', '4.25.1'), acceptable_exit_codes: [0, 1]
      on host, puppet('module', 'install', 'puppetlabs-inifile', '-v', '2.4.0'), acceptable_exit_codes: [0, 1]
      on host, puppet('module', 'install', 'puppetlabs-apache', '-v', '3.4.0'), acceptable_exit_codes: [0, 1]
      on host, puppet('module', 'install', 'puppetlabs-mysql', '-v', '6.2.0'), acceptable_exit_codes: [0, 1]
      on host, puppet('module', 'install', 'puppet-cron', '-v', '1.3.1'), acceptable_exit_codes: [0, 1]
      on host, puppet('module', 'install', 'thias-php', '-v', '1.2.2'), acceptable_exit_codes: [0, 1]
      on host, puppet('module', 'install', 'puppetlabs-firewall', '-v', '1.14.0'), acceptable_exit_codes: [0, 1]
      on host, puppet('module', 'install', 'puppetlabs-vcsrepo', '-v', '1.3.2'), acceptable_exit_codes: [0, 1]
      on host, puppet('module', 'install', 'puppetlabs-git', '-v', '0.5.0'), acceptable_exit_codes: [0, 1]
      on(host, 'cd /etc/puppetlabs/code/modules && git clone https://github.com/SugarFactory/puppet-composer.git composer')
    end
  end
end
