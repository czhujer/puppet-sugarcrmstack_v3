require 'spec_helper_acceptance'

describe 'sugarcrmstack' do
  context 'default parameters' do
    it 'works idempotently with no errors' do
      pp = 'include sugarcrmstack'

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end
  end

  context 'with sub-classes' do
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

        package { 'python-pip':
            ensure  => "installed",
            require => Package['epel-repo'],
            before  => Package['duplicity'],
        }
      }

      package { 'webtatic-release':
        ensure => 'absent',
      }

      if ($::operatingsystemmajrelease in ['6']){

        package { 'mysql-repo':
          ensure   => 'el6-7',
          name     => 'mysql-community-release',
          provider => 'rpm',
          #source => 'http://repo.mysql.com/mysql-community-release-el6.rpm'
          source   => 'https://repo.mysql.com/mysql-community-release-el6-7.noarch.rpm',
        }

        package { "epel-repo":
            name => "epel-release",
            ensure => "installed",
            provider => 'rpm',
            source => 'http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm'
        }

        package { "remi-release":
            ensure => "installed",
            provider => 'rpm',
            source => 'http://remi.mirrors.arminco.com/enterprise/remi-release-6.rpm',
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

        package { "ius-release":
            ensure => "installed",
            provider => 'rpm',
            source => 'http://dl.iuscommunity.org/pub/ius/archive/CentOS/6/x86_64/ius-release-1.0-11.ius.centos6.noarch.rpm',
            require => Package["epel-repo"]
        }

        ini_setting { 'ius-archive enable':
            ensure  => present,
            path    => "/etc/yum.repos.d/ius-archive.repo",
            section => 'ius-archive',
            setting => 'enabled',
            value   => '1',
            require => Package['ius-release'],
        }

        ini_setting { 'ius-archive exclude':
            ensure  => present,
            path    => "/etc/yum.repos.d/ius-archive.repo",
            section => 'ius-archive',
            setting => 'exclude',
            value   => '',
            require => Ini_setting['ius-archive enable'],
        }

      }

      service {'cron':
      }

      # main class
      class { 'sugarcrmstack':
      }

      # classes with real defs

      if ($::operatingsystemmajrelease in ['6']){
        class {'sugarcrmstack::apachephpng':
          php_pkg_version => '5.6.39',
          php_pkg_build   => '1',
        }
      }
      if ($::operatingsystemmajrelease in ['7']){
        class {'sugarcrmstack::apachephpng':
          php_pkg_version     => '5.6.39',
          php_pkg_build       => '1',
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
        sugar_version => '7.5',
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

    describe package('duplicity') do
      it { is_expected.to be_installed }
    end

    describe package('postfix') do
      it { is_expected.to be_installed }
    end

    describe service('crond') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end

    it { is_expected contain_file('/usr/local/bin/automysqlbackup').with_ensure('file') }
    it { is_expected contain_file('/etc/php.ini').with_ensure('file') }
    it { is_expected contain_file('/root/scripts/back2own-duplicity.sh').with_ensure('file') }
  end
end
