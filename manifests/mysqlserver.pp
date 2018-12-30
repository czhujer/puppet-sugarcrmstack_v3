
class sugarcrmstack::mysqlserver (
  $mysql_server_enable='1',
  $mysql_server_service_manage=true,
  $mysql_server_service_enabled=true,
  $mysql_server_service_restart=true,
  $mysql_server_config_max_connections='1024',
  $mysql_server_use_pxc=false,
  #
  $sugar_version=$sugarcrmstack::sugar_version,
  $galeracluster_galeracluster_enable = undef,
  $mysql_override_options=$sugarcrmstack::mysql_override_options,
  $mysql_users_custom=$sugarcrmstack::mysql_users_custom,
  $mysql_grants_custom=$sugarcrmstack::mysql_grants_custom,
  #
  $mysql_sugarcrm_pass_hash=$sugarcrmstack::mysql_sugarcrm_pass_hash,
  $mysql_automysqlbackup_pass_hash=$sugarcrmstack::mysql_automysqlbackup_pass_hash,
  $mysql_root_password=$sugarcrmstack::mysql_root_password,
){

  #variables check
    #variables check
  if (defined(Class['sugarcrmstack']) and $sugar_version == undef) {
    warning "Missing variable \"sugar_version\""
    fail('exiting...')
  }
  elsif (defined(Class['sugarcrmstack_ng']) and $sugarcrmstack_ng::sugar_version == undef) {
    warning "Missing variable \"sugarcrmstack_ng::sugar_version\""
    fail('exiting...')
  }

  if ($galeracluster_galeracluster_enable == 1){
    notice 'Using galeracluster...'
  }
  elsif str2bool($mysql_server_enable){

    if($::operatingsystemmajrelease in ['7'] and $mysql_server_use_pxc == true){
      $mysql_override_options_profile = { 'mysqld' => { 'max_connections' => $mysql_server_config_max_connections,
                                                        #'wsrep_provider'  => 'none',
                                                      }
                                        }
    }
    else{
      $mysql_override_options_profile = { 'mysqld' => { 'max_connections' => $mysql_server_config_max_connections } }
    }

    if($sugar_version == '7.2'){

      exec { 'mysql-libs old':
        command => '/usr/bin/yum -y -d 0 erase mysql-libs-5.1.73-3.el6_5.x86_64',
        path    => '/usr/local/bin/:/bin/',
        onlyif  => 'rpm -q mysql-libs-5.1.73-3.el6_5.x86_64',
        before  => Package[$sugarcrmstack::packages::packages_system_utils],
      }

      exec { 'mysql-libs old2':
        command => '/usr/bin/yum -y -d 0 erase mysql-libs-5.1.71-1.centos6.x86_64',
        path    => '/usr/local/bin/:/bin/',
        onlyif  => 'rpm -q mysql-libs-5.1.71-1.centos6.x86_64',
        before  => Package[$sugarcrmstack::packages::packages_system_utils],
      }

      package { 'mysql55-libs':
        ensure  => '5.5.44-2.ius.centos6',
        require => [
                Ini_setting['webtatic-archive repo exclude packages'],
                Ini_setting['remi repo exclude packages'],
                Ini_setting['centos base repo exclude packages 2'],
                Ini_setting['centos base repo exclude packages'],
                Exec['mysql-libs old'],
                Exec['mysql-libs old2'],
        ]
      }

      $mysql_server_service_name = 'mysqld'
      $mysql_server_package_name = 'mysql55-server'
      $mysql_server_package_ensure = '5.5.44-2.ius.centos6'
      $mysql_server_require = [ Package['mysql55-libs'] ]

    }
    elsif($sugar_version == '7.5') and ($mysql_server_use_pxc == false){

      # set variables
      $mysql_server_packages_old = ['mysql55', 'mysql55-libs', 'mysql55-server']

      $mysql_server_service_name = 'mysqld'
      $mysql_server_package_name = 'mysql-community-server'
      $mysql_server_package_ensure = 'installed'

      if defined(Class['sugarcrmstack_ng::install']){
        $mysql_server_require = [
         Class['sugarcrmstack_ng::install'],
        ]
      }
      else{
        $mysql_server_require = [
          Package['mysql-repo'],
          Package[$mysql_server_packages_old],
          Ini_setting['mysql 5.6 repo enable'],
          Ini_setting['mysql 5.7 repo disable'],
        ]
      }

      # update repos
      if !defined(Class['sugarcrmstack_ng::install']){

        ini_setting { 'mysql 5.6 repo enable':
          ensure  => present,
          path    => '/etc/yum.repos.d/mysql-community.repo',
          section => 'mysql56-community',
          setting => 'enabled',
          value   => '1',
          require => Package['mysql-repo'],
        }

        ini_setting { 'mysql 5.7 repo disable':
          ensure  => present,
          path    => '/etc/yum.repos.d/mysql-community.repo',
          section => 'mysql57-community',
          setting => 'enabled',
          value   => '0',
          require => Package['mysql-repo'],
        }

        # remove old packages
        package { $mysql_server_packages_old:
          ensure   => 'absent',
          provider => 'yum',
          require  => [
            Package['webtatic-release'],
            Ini_setting['remi repo exclude packages'],
            Ini_setting['centos base repo exclude packages 2'],
            Ini_setting['centos base repo exclude packages'],
            Package['mysql-repo'],
          ],
        }
      }
    }
    elsif ($sugar_version == '7.5') and ($mysql_server_use_pxc == true){

      $mysql_server_packages_old = ['mysql55', 'mysql55-libs', 'mysql55-server', 'mysql-community-server', 'mysql-community-client' ]

      if !defined(Class['sugarcrmstack_ng::install']){
        package { 'percona-release':
          ensure   => installed,
          provider => rpm,
          source   => 'https://www.percona.com/redir/downloads/percona-release/redhat/0.1-4/percona-release-0.1-4.noarch.rpm',
        }
      }

      $mysql_server_service_name = 'mysql'
      $mysql_server_package_name = 'Percona-XtraDB-Cluster-server-56'
      $mysql_server_package_ensure = 'installed'

      if defined(Class['sugarcrmstack_ng::install']){
        $mysql_server_require = [
          Class['sugarcrmstack_ng::install'],
        ]
      }
      else{
        $mysql_server_require = [
          Package['percona-release'],
          Package[$mysql_server_packages_old],
          Ini_setting['mysql 5.6 repo enable'],
          Ini_setting['mysql 5.7 repo disable'],
        ]
      }

      if !defined(Class['sugarcrmstack_ng::install']){

        # update repos
        ini_setting { 'mysql 5.6 repo enable':
          ensure  => present,
          path    => '/etc/yum.repos.d/mysql-community.repo',
          section => 'mysql56-community',
          setting => 'enabled',
          value   => '1',
          require => Package['mysql-repo'],
        }

        ini_setting { 'mysql 5.7 repo disable':
          ensure  => present,
          path    => '/etc/yum.repos.d/mysql-community.repo',
          section => 'mysql57-community',
          setting => 'enabled',
          value   => '0',
          require => Package['mysql-repo'],
        }

        package { $mysql_server_packages_old:
          ensure   => absent,
          provider => yum,
          require  => [
            Package['webtatic-release'],
            Ini_setting['remi repo exclude packages'],
            Ini_setting['centos base repo exclude packages 2'],
            Ini_setting['centos base repo exclude packages'],
            Package['percona-release'],
          ],
        }
      }

    }
    elsif ($sugar_version == '7.9') and ($mysql_server_use_pxc == false){

      # set variables
      $mysql_server_packages_old = ['mysql55', 'mysql55-libs', 'mysql55-server']

      $mysql_server_service_name = 'mysqld'
      $mysql_server_package_name = 'mysql-community-server'
      $mysql_server_package_ensure = 'installed'

      if defined(Class['sugarcrmstack_ng::install']){
        $mysql_server_require = [
          Class['sugarcrmstack_ng::install'],
        ]
      }
      else{
        $mysql_server_require = [
          Package['mysql-repo'],
          Package[$mysql_server_packages_old],
          Ini_setting['mysql 5.7 repo enable'],
          Ini_setting['mysql 5.6 repo disable'],
        ]
      }

      # update repos
      if !defined(Class['sugarcrmstack_ng::install']){

        ini_setting { 'mysql 5.7 repo enable':
          ensure  => present,
          path    => '/etc/yum.repos.d/mysql-community.repo',
          section => 'mysql57-community',
          setting => 'enabled',
          value   => '1',
          require => Package['mysql-repo'],
        }

        ini_setting { 'mysql 5.6 repo disable':
          ensure  => present,
          path    => '/etc/yum.repos.d/mysql-community.repo',
          section => 'mysql56-community',
          setting => 'enabled',
          value   => '0',
          require => Package['mysql-repo'],
        }

        #remove old packages
        package { $mysql_server_packages_old:
          ensure   => 'absent',
          provider => 'yum',
          require  => [
            Package['webtatic-release'],
            Ini_setting['remi repo exclude packages'],
            Ini_setting['centos base repo exclude packages 2'],
            Ini_setting['centos base repo exclude packages'],
            Package['mysql-repo'],
          ],
        }
      }
    }
    elsif ($sugar_version == '7.9') and ($mysql_server_use_pxc == true){

      # add percona repo
      if !defined(Class['sugarcrmstack_ng::install']){
        package { 'percona-release':
          ensure   => installed,
          provider => rpm,
          source   => 'https://www.percona.com/redir/downloads/percona-release/redhat/0.1-4/percona-release-0.1-4.noarch.rpm',
        }
      }

      # set variables
      $mysql_server_packages_old = ['mysql55', 'mysql55-libs', 'mysql55-server', 'mysql-community-server', 'mysql-community-client' ]

      $mysql_server_service_name = 'mysql'
      $mysql_server_package_name = 'Percona-XtraDB-Cluster-server-57'
      $mysql_server_package_ensure = 'installed'

      if defined(Class['sugarcrmstack_ng::install']){
        $mysql_server_require = [
          Class['sugarcrmstack_ng::install'],
        ]
      }
      else{
        $mysql_server_require = [
                                 Package['percona-release'],
                                 Package[$mysql_server_packages_old] ,
                                 Ini_setting['mysql 5.7 repo enable'],
                                 Ini_setting['mysql 5.6 repo disable'],
                                ]
      }

      if !defined(Class['sugarcrmstack_ng::install']){

        # update repos
        ini_setting { 'mysql 5.7 repo enable':
          ensure  => present,
          path    => '/etc/yum.repos.d/mysql-community.repo',
          section => 'mysql57-community',
          setting => 'enabled',
          value   => '1',
          require => Package['mysql-repo'],
        }

        ini_setting { 'mysql 5.6 repo disable':
          ensure  => present,
          path    => '/etc/yum.repos.d/mysql-community.repo',
          section => 'mysql56-community',
          setting => 'enabled',
          value   => '0',
          require => Package['mysql-repo'],
        }

        #remove old packages
        package { $mysql_server_packages_old:
          ensure   => absent,
          provider => yum,
          require  => [
                     Package['webtatic-release'],
                     Ini_setting['remi repo exclude packages'],
                     Ini_setting['centos base repo exclude packages 2'],
                     Ini_setting['centos base repo exclude packages'],
                     Package['percona-release']
         ],
        }

      }
    }
    elsif($sugarcrmstack_ng::sugar_version == '7.5') and ($mysql_server_use_pxc == false){

      # set variables
      $mysql_server_service_name = 'mysqld'
      $mysql_server_package_name = 'mysql-community-server'
      $mysql_server_package_ensure = 'installed'
      $mysql_server_require = []
    }
    elsif ($sugarcrmstack_ng::sugar_version == '7.5') and ($mysql_server_use_pxc == true){

      $mysql_server_service_name = 'mysql'
      $mysql_server_package_name = 'Percona-XtraDB-Cluster-server-56'
      $mysql_server_package_ensure = 'installed'
      $mysql_server_require = []
    }
    elsif ($sugarcrmstack_ng::sugar_version == '7.9' or $sugarcrmstack_ng::sugar_version == '8.0' or $sugar_version == '8.0') and ($mysql_server_use_pxc == false){

      $mysql_server_service_name = 'mysqld'
      $mysql_server_package_name = 'mysql-community-server'
      $mysql_server_package_ensure = 'installed'
      $mysql_server_require = []
    }
    elsif ($sugarcrmstack_ng::sugar_version == '7.9' or $sugarcrmstack_ng::sugar_version == '8.0' or $sugar_version == '8.0') and ($mysql_server_use_pxc == true){

      $mysql_server_service_name = 'mysql'
      $mysql_server_package_name = 'Percona-XtraDB-Cluster-server-57'
      $mysql_server_package_ensure = 'installed'
      $mysql_server_require = []
    }
    else{
      warning "I can't run with sugarcrm version ${sugar_version} / ${sugarcrmstack_ng::sugar_version}"
      fail('exiting...')
    }

    $mysql_override_options_final = deep_merge($mysql_override_options, $mysql_override_options_profile)

    $mysql_users_default = {
       'sugarcrm@localhost' => {
         ensure                   => 'present',
         password_hash            => $mysql_sugarcrm_pass_hash,
        },
       'automysqlbackup@localhost' => {
         ensure                   => 'present',
         password_hash            => $mysql_automysqlbackup_pass_hash,
       },
      }

    $mysql_users = deep_merge($mysql_users_custom,$mysql_users_default)

    $mysql_grants_default = {
        'sugarcrm@localhost/sugarcrm.*' => {
          ensure     => 'present',
          #options    => ['GRANT'],
          privileges => ['CREATE', 'ALTER', 'DELETE', 'INSERT', 'SELECT', 'UPDATE', 'LOCK TABLES', 'DROP',
    			'CREATE ROUTINE', 'ALTER ROUTINE', 'EXECUTE', 'CREATE TEMPORARY TABLES', 'INDEX'],
          table      => 'sugarcrm.*',
          user       => 'sugarcrm@localhost',
        },
        'automysqlbackup@localhost/*.*' => {
          ensure     => 'present',
          #options    => ['GRANT'],
          privileges => ['SELECT', 'LOCK TABLES', 'SHOW VIEW', 'EXECUTE' ],
          table      => '*.*',
          user       => 'automysqlbackup@localhost',
        },
       }

    $mysql_grants = deep_merge($mysql_grants_custom,$mysql_grants_default)

    class { '::mysql::server':
      root_password    => $mysql_root_password,
      override_options => $mysql_override_options_final,
      users            => $mysql_users,
      grants           => $mysql_grants,
      package_name     => $mysql_server_package_name,
      package_ensure   => $mysql_server_package_ensure,
      service_manage   => $mysql_server_service_manage,
      service_enabled  => $mysql_server_service_enabled,
      service_name     => $mysql_server_service_name,
      restart          => $mysql_server_service_restart,
      require          => $mysql_server_require,
    }

    # slow query log
    file { 'mysql-server slow query log':
      ensure  => present,
      path    => '/var/log/mysql-slow.log',
      owner   => 'mysql',
      group   => 'mysql',
      mode    => '0640',
      notify  => Service['mysqld'],
      #require => Package['$mysql_server_package_name'],
      require => Class['::mysql::server::install'],
    }

    # logrotate for mysql slow-query log
    file { 'mysql-server slow query log logrotate':
      ensure  => present,
      path    => '/etc/logrotate.d/mysql-slow',
      content => template('sugarcrmstack/logrotate.conf.mysql-slow.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }

  } #end of if str2bool($mysql_server_enable)
  else{
    warning 'Mysqlserver is disable'
  }

} #end of class
