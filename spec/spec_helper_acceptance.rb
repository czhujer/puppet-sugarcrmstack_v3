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
hosts.each do |host|
  on(host, "ls -lh /etc/puppetlabs/code/modules/sugarcrmstack/*")
end

install_module_dependencies

RSpec.configure do |c|
  # Readable test descriptions
  c.formatter = :documentation
  hosts.each do |host|
    if host[:platform] =~ %r{el-6-x86_64} && host[:hypervisor] =~ %r{docker}
      on(host, "sed -i '/nodocs/d' /etc/yum.conf")
    end
    if host[:platform] =~ %r{el-7-x86_64} && host[:hypervisor] =~ %r{docker}
      on(host, "sed -i '/nodocs/d' /etc/yum.conf")
    end
  end
end
