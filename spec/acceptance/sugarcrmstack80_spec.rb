require 'spec_helper_acceptance'

describe 'sugarcrmstack v8.0' do

  if os[:family] == 'redhat'
    if os[:release] == '7'

      context 'v80 with sub-classes and basic setup' do
        # Using puppet_apply as a helper
        it 'works with no errors' do
          pp = <<-EOS

          # necessary defs, because we dont have install class
          #
          if ($::operatingsystemmajrelease in ['7']){

            package { 'mysql-repo':
              ensure   => 'el7-5',
              name     => 'mysql-community-release',
              provider => 'rpm',
              #source => 'http://repo.mysql.com/mysql-community-release-el7.rpm'
              source   => 'https://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm',
            }

            package { "epel-repo":
                name => "epel-release",
                ensure => "installed",
                provider => 'rpm',
                source => 'http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm '
            }

            package { "remi-release":
                ensure => "installed",
                provider => 'rpm',
                source => 'http://remi.mirrors.arminco.com/enterprise/remi-release-7.rpm',
                require => Package["epel-repo"]
            }

            ini_setting { 'remi repo enable':
                ensure  => present,
                path    => "/etc/yum.repos.d/remi.repo",
                section => 'remi',
                setting => 'enabled',
                value   => 1,
                require => Package["remi-release"],
            }

            ini_setting { 'remi repo exclude packages':
                ensure  => present,
                path    => "/etc/yum.repos.d/remi.repo",
                section => 'remi',
                setting => 'exclude',
                value   => "mysql-server* php* mysql-libs",
                require => Ini_setting["remi repo enable"],
            }

            ini_setting { 'centos base repo exclude packages':
                ensure  => present,
                path    => "/etc/yum.repos.d/CentOS-Base.repo",
                section => 'base',
                setting => 'exclude',
                value   => 'mysql-server* glusterfs*',
            }

            ini_setting { 'centos base repo exclude packages 2':
                ensure  => present,
                path    => "/etc/yum.repos.d/CentOS-Base.repo",
                section => 'updates',
                setting => 'exclude',
                value   => "mysql-server*",
            }

            ini_setting { 'enable remi-php56 repo':
              ensure  => present,
              path    => '/etc/yum.repos.d/remi.repo',
              section => 'remi-php56',
              setting => 'enabled',
              value   => '1',
              before  => Class['sugarcrmstack::apachephpng'],
            }

            # log folder2
            file { 'mysql-server log folder2':
              ensure  => directory,
              path    => '/var/log/mariadb',
              owner   => 'mysql',
              group   => 'mysql',
              mode    => '0755',
              #before  => Class['sugarcrmstack::mysqlserver'],
              require => Package['mysql-server'],
            }

            # slow query log2
            file { 'mysql-server slow query log2':
              ensure  => present,
              path    => '/var/log/mariadb/mysql-slow.log',
              owner   => 'mysql',
              group   => 'mysql',
              mode    => '0644',
              #before  => Class['sugarcrmstack::mysqlserver'],
              require => File['mysql-server log folder2'],
            }

          }

          service {'cron':
          }

          # main class
          class { 'sugarcrmstack':
          }

          # classes with real defs

          if ($::operatingsystemmajrelease in ['7']){
            class {'sugarcrmstack::apachephpng':
              php_pkg_version     => '7.1.25',
              php_pkg_build       => '2',
              apache_default_mods => [ 'actions', 'authn_core', 'cache', 'ext_filter', 'mime', 'mime_magic', 'rewrite', 'speling',
                                            'version', 'vhost_alias', 'auth_digest', 'authn_anon', 'authn_dbm', 'authz_dbm', 'authz_owner',
                                            'expires', 'include', 'logio', 'substitute', 'usertrack', 'alias',
                                            'authn_file', 'autoindex', 'dav', 'dav_fs', 'dir', 'negotiation', 'setenvif', 'auth_basic',
                                            'authz_user', 'authz_groupfile', 'env', 'suexec']
            }
          }

          class {'sugarcrmstack::back2own':
          }

          class { 'sugarcrmstack::mysqlserver':
            sugar_version => '8.0',
          }

          class {'sugarcrmstack::mysqlbackup':
          }

          class {'sugarcrmstack::postfixserver':
            postfix_server_fqdn => $fqdn,
            #postfix_service_enable => undef,
            postfix_service_ensure => false,
          }

          class {'sugarcrmstack::sugarcrm':
          }

          EOS

          apply_manifest(pp, catch_failures: true)
        end

        describe package('httpd') do
          it { is_expected.to be_installed }
        end

        describe service('httpd') do
          it { is_expected.to be_enabled }
          it { is_expected.to be_running }
        end

        describe package('mysql-community-server') do
          it { is_expected.to be_installed }
        end

        describe service('mysqld') do
          it { is_expected.to be_enabled }
          it { is_expected.to be_running }
        end

        describe package('postfix') do
          it { is_expected.to be_installed }
        end

        describe service('crond') do
          it { is_expected.to be_enabled }
          it { is_expected.to be_running }
        end

        describe file('/usr/bin/duplicity') do
          it { is_expected.to be_file }
        end

        describe file('/usr/local/bin/automysqlbackup') do
          it { is_expected.to be_file }
        end

        describe file('/etc/php.ini') do
          it { is_expected.to be_file }
        end

        describe file('/root/scripts/back2own-duplicity.sh') do
          it { is_expected.to be_file }
        end
      end
    end
  end

end
