class sugarcrmstack::apachephpng (
$apache_serveradmin='info@sugarfactory.cz',
$apache_mpm='prefork', #or worker
$apache_https_port=443,
$apache_http_port=80,
$apache_http_redirect=true,
$apache_timeout=60,
$apache_keepalive='On',
$apache_default_mods=[ 'actions', 'authn_core', 'cache', 'ext_filter', 'mime', 'mime_magic', 'rewrite', 'speling', 'suexec', 'version', 'vhost_alias', 'auth_digest', 'authn_anon', 'authn_dbm', 'authz_dbm', 'authz_owner', 'expires', 'include', 'logio', 'substitute', 'usertrack', 'authn_alias', 'authn_default', 'alias', 'authn_file', 'autoindex', 'dav', 'dav_fs', 'deflate', 'dir', 'negotiation', 'setenvif', 'auth_basic', 'authz_user', 'authz_groupfile', 'env', 'authz_default', ],
$apache_service_manage=true,
$apache_service_enable=true,
$apache_service_ensure='running',
$apache_manage_user=true,
$apache_main_vhost_custom_fragment='',
$proxy_pass_match=[],
$apache_ssl_chain=undef,
$php_max_execution_time=90,
$php_memory_limit='512M',
$php_upload_max_filesize='10M',
$php_post_max_size='10M',
$php_session_gc_maxlifetime=3600,
$php_session_save_handler='files', #or memcache, redis
$php_session_save_path='/var/lib/php/session', # or IP/host memcache
$php_session_phpmyadmin_save_path='/var/lib/php/session-phpmyadmin',
$php_pkg_version='5.4.45', #or 5.5
$php_pkg_build='1',
$php_cache_engine='opcache', #or apc or opcache+apcu or absent (for disabling cache)
$php_error_reporting='E_ALL & ~E_DEPRECATED & ~E_NOTICE & ~E_STRICT & ~E_NOTICE',
$use_php_mysqlnd=true,
$manage_firewall=true,
$manage_phpmyadmin_config=true, #false
$manage_phpmyadmin_files=true,
$phpmyadmin_files_repo_tag='RELEASE_4_8_4',
$phpmyadmin_files_repo_depth=1,
$manage_sugarcrm_files_ownership=true,
$xdebug_module_manage=true,
$xdebug_module_ensure='absent',
$xdebug_module_settings={
  'xdebug.remote_enable' => '0',
  'xdebug.default_enable' => '0',
  },
$php_fpm_manage_phpmyadmin_user=true,
){

  validate_integer($apache_timeout)

  validate_integer($php_max_execution_time)

  validate_integer($php_session_gc_maxlifetime)

  validate_integer($phpmyadmin_files_repo_depth)

  validate_bool($apache_http_redirect)

  validate_bool($use_php_mysqlnd)

  validate_bool($manage_firewall)

  validate_bool($manage_sugarcrm_files_ownership)

  #validate_re('${xdebug_module_ensure}', '^[absent|present]$')
  validate_re($xdebug_module_ensure, ['^absent$', '^present$'] )

  unless $php_upload_max_filesize =~ /^[0-9]{1,10}(K|M|G)?/ {
    fail('Class[\'sugarcrmstack::apachephpng\']: php_upload_max_filesize has wrong value (regexp: /^[0-9]{1,10}(K|M|G)/)')
  }

  unless $php_post_max_size =~ /^[0-9]{1,10}(K|M|G)?/ {
    fail('Class[\'sugarcrmstack::apachephpng\']: php_post_max_size has wrong value (regexp: /^[0-9]{1,10}(K|M|G)/)')
  }

  unless $php_memory_limit =~ /^[0-9]{1,10}(K|M|G)?/ {
    fail('Class[\'sugarcrmstack::apachephpng\']: php_memory_limit has wrong value (regexp: /^[0-9]{1,10}(K|M|G)/)')
  }

  if defined(Class['sugarcrmstack_ng']){
    if ($::sugarcrmstack_ng::sugar_version != '7.5' and $::sugarcrmstack_ng::sugar_version != '7.9' and $::sugarcrmstack_ng::sugar_version != '8.0'){
      fail("Class['sugarcrmstack_ng::apachephpng']: This class is compatible only with sugar_version 7.5,7.9 or 8.0 (not ${::sugarcrmstack_ng::sugar_version})")
    }
  }
  else{
    if ($sugarcrmstack::sugar_version != '7.5' and $sugarcrmstack::sugar_version != '7.9'){
      fail("Class['sugarcrmstack::apachephpng']: This class is compatible only with sugar_version 7.5 or 7.9 (not ${sugarcrmstack::sugar_version})")
    }
  }

  unless is_integer($apache_https_port){
    fail("Class['sugarcrmstack::apachephpng']: apache_https_port is not intenger: ${apache_https_port}")
  }

  unless is_integer($apache_http_port){
    fail("Class['sugarcrmstack::apachephpng']: apache_http_port is not intenger: ${apache_http_port}")
  }

  if($php_session_save_handler== 'memcache' and $php_session_save_path == '/var/lib/php/session'){
    fail("Class['sugarcrmstack::apachephpng']: PHP session_save_path cant be folder with memcache engine")
   }

  if($php_session_save_handler== 'redis' and $php_session_save_path == '/var/lib/php/session'){
    fail("Class['sugarcrmstack::apachephpng']: PHP session_save_path can't be folder with redis engine")
   }

  if($php_pkg_version =~ /^5\.4\.[3-4][0-9]$/){
    $php_common_package_name = 'php54-common'
    $php_cli_package_name = 'php54-cli'
    $php_apc_name         = 'apc'
    $php_opcache_name     = 'pecl-zendopcache'
    $php_pkg_version_full = "${php_pkg_version}-${php_pkg_build}.ius.centos6"
    $php_pkg_prefix       = 'php54'

    if($use_php_mysqlnd == true){
      $php_pkg_mysql = 'php54-mysqlnd'
    }
    else{
      $php_pkg_mysql = 'php54-mysql'
    }

    unless($sugarcrmstack::support_for_old_php == 1){
      fail("Class['sugarcrmstack::apachephpng']: This class needs param support_for_old_php to \"1\" (not ${sugarcrmstack::support_for_old_php})")
    }

  }
  elsif($php_pkg_version =~ /^5\.5\.[0-3]{0,1}[0-9]/){
    $php_common_package_name = 'php55u-common'
    $php_cli_package_name = 'php55u-cli'
    $php_apc_name         = 'apcu'
    $php_opcache_name     = 'opcache'
    $php_pkg_version_full = "${php_pkg_version}-${php_pkg_build}.ius.centos6"
    $php_pkg_prefix       = 'php55u'
    $php_pkg_mysql        = 'php55u-mysqlnd'
  }
  elsif($php_pkg_version =~ /^5\.6\.[0-3]{0,1}[0-9]/ and $::operatingsystemmajrelease in ['7']){
    $php_common_package_name = 'php-common'
    $php_cli_package_name = 'php-cli'
    $php_apc_name         = 'apcu'
    $php_opcache_name     = 'opcache'
    $php_pkg_version_full = "${php_pkg_version}-${php_pkg_build}.el7.remi"
    $php_pkg_prefix       = 'php'
    $php_pkg_mysql        = 'php-mysqlnd'
  }
  elsif($php_pkg_version =~ /^5\.6\.[0-3]{0,1}[0-9]/){
    $php_common_package_name = 'php56u-common'
    $php_cli_package_name = 'php56u-cli'
    $php_apc_name         = 'apcu'
    $php_opcache_name     = 'opcache'
    $php_pkg_version_full = "${php_pkg_version}-${php_pkg_build}.ius.centos6"
    $php_pkg_prefix       = 'php56u'
    $php_pkg_mysql        = 'php56u-mysqlnd'
  }
  elsif($php_pkg_version =~ /^7\.1\.[0-9][0-9]/){
    $php_common_package_name = 'php-common'
    $php_cli_package_name = 'php-cli'
    $php_apc_name         = 'apcu'
    $php_opcache_name     = 'opcache'
    $php_pkg_version_full = "${php_pkg_version}-${php_pkg_build}.el7.remi"
    $php_pkg_prefix       = 'php'
    $php_pkg_mysql        = 'php-mysqlnd'
  }
  else {
    fail("Class['sugarcrmstack::apachephpng']: Unsupported PHP version: ${php_pkg_version}")
  }

  if ($::operatingsystemmajrelease in ['7']){
    $directories_sugarcrm_ssl1 =
      {
         path             => '/var/www/html/sugarcrm',
         provider         => 'directory',
         require          => 'all granted',
         allow_override   => ['all'],
         options          => ['all']
       }

    $directories_sugarcrm_ssl2 =
       {
         path             => '/var/www/html',
         provider         => 'directory',
         require          => 'all granted',
         allow_override   => ['all'],
         options          => ['all']
      }


    if($manage_phpmyadmin_config){
      $aliases_phpmyadmin1 = {
          alias            => '/phpMyAdmin',
          path             => '/usr/share/phpMyAdmin'
        }
      $aliases_phpmyadmin2 = {
          alias            => '/phpmyadmin',
          path             => '/usr/share/phpMyAdmin'
        }

      $aliases_phpmyadmin = [$aliases_phpmyadmin1, $aliases_phpmyadmin2]

      $directories_phpmyadmin1 =
        {
          path             => '/usr/share/phpMyAdmin/',
          provider         => 'directory',
          require          => 'all granted',
          adddefaultcharset => 'UTF-8',
        }

      $directories_phpmyadmin2 =
        {
          path             => '/usr/share/phpMyAdmin/setup/',
          provider         => 'directory',
          require          => 'all denied',
        }

      $directories_phpmyadmin3 =
        {
          path             => '/usr/share/phpMyAdmin/libraries/',
          provider         => 'directory',
          require          => 'all denied',
        }

      $directories_phpmyadmin4 =
        {
          path             => '/usr/share/phpMyAdmin/setup/lib/',
          provider         => 'directory',
          require          => 'all denied',
        }

      $directories_phpmyadmin5 =
        {
          path             => '/usr/share/phpMyAdmin/.git',
          provider         => 'directory',
          require          => 'all denied',
        }

      $directories_phpmyadmin6 =
        {
          path             => '/usr/share/phpMyAdmin/setup/frames/',
          provider         => 'directory',
          require          => 'all denied',
        }

      $directories_all = [ $directories_sugarcrm_ssl1, $directories_sugarcrm_ssl2,
                                    $directories_phpmyadmin1, $directories_phpmyadmin2,
                                    $directories_phpmyadmin3, $directories_phpmyadmin4,
                                    $directories_phpmyadmin5, $directories_phpmyadmin6,
                         ]
    }
    else{
      $aliases_phpmyadmin = []
      $directories_all = [ $directories_sugarcrm_ssl1, $directories_sugarcrm_ssl2, ]
    }

  }
  else{
    $directories_sugarcrm_ssl1 =
      {
         path             => '/var/www/html/sugarcrm',
         provider         => 'directory',
         order            => 'Allow,Deny',
         'allow'          => 'from all',
         allow_override   => ['all'],
         options          => ['all']
       }

    $directories_sugarcrm_ssl2 =
       {
         path             => '/var/www/html',
         provider         => 'directory',
         order            => 'Allow,Deny',
         'allow'          => 'from all',
         allow_override   => ['all'],
         options          => ['all']
      }


    if($manage_phpmyadmin_config){
      $aliases_phpmyadmin1 = {
          alias            => '/phpMyAdmin',
          path             => '/usr/share/phpMyAdmin'
        }
      $aliases_phpmyadmin2 = {
          alias            => '/phpmyadmin',
          path             => '/usr/share/phpMyAdmin'
        }

      $aliases_phpmyadmin = [$aliases_phpmyadmin1, $aliases_phpmyadmin2]

      $directories_phpmyadmin1 =
        {
          path             => '/usr/share/phpMyAdmin/',
          provider         => 'directory',
          order            => 'Allow,Deny',
          'allow'          => 'from all',
          adddefaultcharset => 'UTF-8',
        }

      $directories_phpmyadmin2 =
        {
          path             => '/usr/share/phpMyAdmin/setup/',
          provider         => 'directory',
          order            => 'Deny,Allow',
          'deny'          => 'from All',
          'allow'          => 'from None',
        }

      $directories_phpmyadmin3 =
        {
          path             => '/usr/share/phpMyAdmin/libraries/',
          provider         => 'directory',
          order            => 'Deny,Allow',
          'deny'           => 'from All',
          'allow'          => 'from None',
        }

      $directories_phpmyadmin4 =
        {
          path             => '/usr/share/phpMyAdmin/setup/lib/',
          provider         => 'directory',
          order            => 'Deny,Allow',
          'deny'           => 'from All',
          'allow'          => 'from None',
        }

      $directories_phpmyadmin5 =
        {
          path             => '/usr/share/phpMyAdmin/.git',
          provider         => 'directory',
          order            => 'Deny,Allow',
          'deny'           => 'from All',
          'allow'          => 'from None',
        }

      $directories_phpmyadmin6 =
        {
          path             => '/usr/share/phpMyAdmin/setup/frames/',
          provider         => 'directory',
          order            => 'Deny,Allow',
          'deny'           => 'from All',
          'allow'          => 'from None',
        }

      $directories_all = [ $directories_sugarcrm_ssl1, $directories_sugarcrm_ssl2,
                                    $directories_phpmyadmin1, $directories_phpmyadmin2,
                                    $directories_phpmyadmin3, $directories_phpmyadmin4,
                                    $directories_phpmyadmin5, $directories_phpmyadmin6,
                         ]
    }
    else{
      $aliases_phpmyadmin = []
      $directories_all = [ $directories_sugarcrm_ssl1, $directories_sugarcrm_ssl2, ]
    }

  }

  if($php_session_save_handler == 'redis'){
    $php_session_phpmyadmin_save_path_final = $php_session_save_path
  }
  else{
    $php_session_phpmyadmin_save_path_final = $php_session_phpmyadmin_save_path
  }

  class { 'apache':
    mpm_module           => false,
    default_vhost        => false,
    purge_configs        => true,
    #purge_vdir           => true,
    #mod_enable_dir       => false,
    #
    serveradmin          => $apache_serveradmin,
    server_signature     => 'off',
    server_tokens        => 'prod',
    keepalive            => $apache_keepalive,
    keepalive_timeout    => 2,
    timeout              => $apache_timeout,
    #
    default_mods         => $apache_default_mods,
    #
    service_manage       => $apache_service_manage,
    service_enable       => $apache_service_enable,
    service_ensure       => $apache_service_ensure,
    #
    manage_user          => $apache_manage_user,
  }

  if($apache_mpm == 'worker' ){
    class { 'apache::mod::worker':
      serverlimit     => '6', # >= maxclients / ThreadsPerChild
      startservers    => '2',
      maxclients      => '100',
      threadlimit     => '25',
      threadsperchild => '25',
    }
  }
  elsif($apache_mpm == 'prefork'){
    class { 'apache::mod::prefork':
    }
  }
  else{
    fail("Class['sugarcrmstack::apachephpng']: Unsupported MPM: ${apache_mpm}")
  }

#  class { 'apache::mod::php':
#    package_name => 'php56u',
#    require => Ini_setting['ius repo exclude php56u'],
#  }

  class { 'apache::mod::status':
    allow_from      => ['127.0.0.1','::1'],
    extended_status => 'On',
    status_path     => '/server-status',
  }

  class { 'apache::mod::ssl':
  }

  class { 'php::cli':
    ensure => $php_pkg_version_full,
    cli_package_name => $php_cli_package_name,
  }

  class { 'php::common':
    common_package_name => $php_common_package_name,
    require => Class['php::cli'],
  }

  if ($::sugarcrmstack_ng::sugar_version == '8.0'){

    class { 'apache::mod::proxy':
    }
    class { 'apache::mod::proxy_fcgi':
    }

    #apache::fastcgi::server { 'php':
    #  host       => '127.0.0.1:9001',
    #  timeout    => 10,
    #  flush      => false,
    #  faux_path  => '/var/www/php.fcgi',
    #  fcgi_alias => '/php.fcgi',
    #  file_type  => 'application/x-httpd-php'
    #}

  }
  else{
    class { 'php::mod_php5':
      php_package_name => $php_pkg_prefix,
      require => Class['php::cli'],
    }
  }

  php::ini { '/etc/php.ini':
     error_reporting            => "${php_error_reporting}",
     memory_limit               => "${php_memory_limit}",
     date_timezone              => 'Europe/Berlin',
     max_execution_time         => $php_max_execution_time,
     allow_url_fopen            => 'On',
     upload_max_filesize        => $php_upload_max_filesize,
     post_max_size              => $php_post_max_size,
     session_gc_maxlifetime     => $php_session_gc_maxlifetime,
     session_save_handler       => $php_session_save_handler,
     session_save_path          => $php_session_save_path,
  }

  $php_modules = [ "${php_pkg_prefix}-mcrypt",
                   "${php_pkg_prefix}-imap",
                   "${php_pkg_prefix}-soap",
                   'php-php-gettext',
                   'php-tcpdf',
                   'php-tcpdf-dejavu-sans-fonts',
#                   "${php_pkg_prefix}-opcache",
#                   "${php_pkg_prefix}-memcache",
                   "${php_pkg_mysql}",
                   "${php_pkg_prefix}-pecl-redis",
#                   "${php_pkg_prefix}-pecl-apcu",
#                   "${php_pkg_prefix}-pecl-xdebug",
                  ]

  php::module { $php_modules:
     require => [
                 #Class['php::mod_php5'],
                 Class['php::common'],
                ],
  }

  if ($::sugarcrmstack_ng::sugar_version == '8.0'){
    php::fpm::conf { 'www':
        package_name => "${php_pkg_prefix-fpm}",
        listen  => '127.0.0.1:9001',
        user    => 'apache',
        pm_status_path => '/fpm-status',
        ping_path    => '/fpm-ping',
        #
        php_value => {
          error_reporting            => "${php_error_reporting}",
          memory_limit               => "${php_memory_limit}",
          date_timezone              => 'Europe/Berlin',
          max_execution_time         => $php_max_execution_time,
          allow_url_fopen            => 'On',
          upload_max_filesize        => $php_upload_max_filesize,
          post_max_size              => $php_post_max_size,
          session_gc_maxlifetime     => $php_session_gc_maxlifetime,
          session_save_handler       => $php_session_save_handler,
          session_save_path          => $php_session_save_path,
        },
    }~>File['/var/log/php-fpm']

    if($manage_phpmyadmin_files == true){
      $require_session_phpmyadmin = Package['phpMyAdmin']
    }
    else{
      $require_session_phpmyadmin = []
    }

    file { '/var/lib/php/session-phpmyadmin':
        ensure  => 'directory',
        mode    => '750',
        owner   => 'phpmyadmin',
        group   => 'phpmyadmin',
        require => $require_session_phpmyadmin,
    }

    file { '/var/log/php-fpm/phpmyadmin-error.log':
      ensure  => 'file',
      owner   => 'phpmyadmin',
      group   => 'phpmyadmin',
      require => File['/var/log/php-fpm'],
      notify  => Service['php-fpm'],
    }

    if($php_fpm_manage_phpmyadmin_user){
      user { 'phpmyadmin':
        ensure     => present,
#        home       => '/home/phpmyadmin',
        managehome => true,
        system     => true,
        shell      => '/sbin/nologin',
      }
    }

    php::fpm::conf { 'phpmyadmin':
        package_name => "$php_pkg_prefix-fpm",
        listen  => '127.0.0.1:9002',
        user    => 'phpmyadmin',
        pm_status_path => '/fpm-status',
        ping_path    => '/fpm-ping',
        php_admin_value => {
          'session.save_handler' => $php_session_save_handler,
          'session.save_path'    => $php_session_phpmyadmin_save_path_final,
        },
    }~>File['/var/log/php-fpm']

    class { php::fpm::daemon:
          ensure => present,
          package_name => "$php_pkg_prefix-fpm",
  #        log_owner => 'php-fpm',
  #        log_group => 'root',
  #        log_dir_mode => '0770',
          log_owner => 'apache',
          log_group => 'apache',
          log_dir_mode => '0775',
    }
  }

  if($php_cache_engine == 'apcu'){

    php::module { "${php_pkg_prefix}-pecl-${php_apc_name}":
       ensure  => installed,
       require => [
                 #Class['php::mod_php5'],
                 Class['php::common'],
                ],
    }

    php::module { "${php_pkg_prefix}-${php_opcache_name}":
       ensure  => absent,
       require => [
                 #Class['php::mod_php5'],
                 Class['php::common'],
                ],
    }

    php::module::ini { 'pecl-apcu':
      pkgname => "${php_pkg_prefix}-pecl-${php_apc_name}",
      prefix  => '40',
      settings => {
        'apc.enabled'      => '1',
        'apc.optimization' => '1',
        'apc.shm_segments' => '1',
        'apc.shm_size'     => '32M',
        'apc.user_ttl'     => '0',
        'apc.ttl'          => '0',
        'apc.cache_by_default' => '1',
        'apc.num_files_hint' => '10000',
        'apc.mmap_file_mask' => '/tmp/apc.XXXXXX',
      },
    }

  } #end of apcu
  elsif($php_cache_engine == 'opcache'){

    php::module { "${php_pkg_prefix}-pecl-${php_apc_name}":
       ensure  => absent,
       require => [
                 #Class['php::mod_php5'],
                 Class['php::common'],
                ],
       notify  => Service['httpd'],
    }

    php::module { "${php_pkg_prefix}-${php_opcache_name}":
       ensure  => installed,
       require => [
                 #Class['php::mod_php5'],
                 Class['php::common'],
                ],
       notify  => Service['httpd'],
    }

    php::module::ini { 'opcache':
      pkgname => "${php_pkg_prefix}-${php_opcache_name}",
      prefix  => '10',
      zend    => true,
      settings => {
        'opcache.enable'                     => '1',
        'opcache.fast_shutdown'              => '1',
        'opcache.interned_strings_buffer'    => '16',
        'opcache.max_accelerated_files'      => '1000000',
        'opcache.memory_consumption'         => '256',
        'opcache.revalidate_freq'            => '0',
        'opcache.revalidate_path'            => '1',
      },
    }

  } #end of opcache
  elsif($php_cache_engine == 'opcache+apcu'){

    php::module { "${php_pkg_prefix}-pecl-apcu":
       ensure  => installed,
       require => [
                 #Class['php::mod_php5'],
                 Class['php::common'],
                ],
       notify  => Service['httpd'],
    }

    php::module::ini { 'pecl-apcu':
      pkgname => "${php_pkg_prefix}-pecl-apcu",
      prefix  => '40',
      settings => {
        'apc.enabled'      => '1',
        'apc.optimization' => '1',
        'apc.shm_segments' => '1',
        'apc.shm_size'     => '32M',
        'apc.user_ttl'     => '0',
        'apc.ttl'          => '0',
        'apc.cache_by_default' => '1',
        'apc.num_files_hint' => '10000',
        'apc.mmap_file_mask' => '/tmp/apc.XXXXXX',
      },
      notify  => Service['httpd'],
    }

    php::module { "${php_pkg_prefix}-opcache":
       ensure  => installed,
       require => [
                 #Class['php::mod_php5'],
                 Class['php::common'],
                ],
       notify  => Service['httpd'],
    }

    php::module::ini { 'opcache':
      pkgname => "${php_pkg_prefix}-opcache",
      prefix  => '10',
      zend    => true,
      settings => {
        'opcache.enable'                     => '1',
        'opcache.fast_shutdown'              => '1',
        'opcache.interned_strings_buffer'    => '16',
        'opcache.max_accelerated_files'      => '1000000',
        'opcache.memory_consumption'         => '256',
        'opcache.revalidate_freq'            => '0',
        'opcache.revalidate_path'            => '1',
      },
      notify  => Service['httpd'],
    }

  }
  elsif($php_cache_engine == 'absent'){

    php::module { "${php_pkg_prefix}-pecl-${php_apc_name}":
       ensure  => absent,
       require => [
                 #Class['php::mod_php5'],
                 Class['php::common'],
                ],
    }

    php::module { "${php_pkg_prefix}-${php_opcache_name}":
       ensure  => absent,
       require => [
                 #Class['php::mod_php5'],
                 Class['php::common'],
                ],
    }

  } #end of absent
  else{
    fail("Class['sugarcrmstack::apachephpng']: Unsupported PHP cache engine: ${php_cache_engine}")
  } #end of cache engine

  if($xdebug_module_manage){

    php::module { "${php_pkg_prefix}-pecl-xdebug":
       ensure  => $xdebug_module_ensure,
       require => [
                 #Class['php::mod_php5'],
                 Class['php::common'],
                ],
       notify  => Service['httpd'],
    }

    php::module::ini { 'pecl-xdebug':
      ensure   => $xdebug_module_ensure,
      pkgname  => "${php_pkg_prefix}-pecl-xdebug",
      prefix   => '15',
      settings => $xdebug_module_settings,
      zend     => true,
      notify   => Service['httpd'],
    }

  }

#  php::module::ini { 'memcache':
#    pkgname => "php55u-pecl-memcache",
#    prefix  => '40',
#    settings => {
#      'session.save_handler'      => 'memcache',
#      'session.save_path'         => '"tcp://localhost:11211?persistent=1&weight=1&timeout=1&retry_interval=15"',
#    },
#  }

  if($apache_http_redirect){

    apache::vhost { 'sugarcrm':
      serveraliases   => '*',
      port            => $apache_http_port,
      docroot         => '/var/www/html/sugarcrm-http',
      error_log_file  => 'error_log',
      access_log_file => 'access_log',
      rewrites => [
        {
          comment      => 'redirect to TTTPS',
          rewrite_cond => ['%{SERVER_PORT} !^443$'],
          rewrite_rule => ['^/(.*) https://%{HTTP_HOST}/$1 [NC,R,L]'],
        },
      ],
    }

  }
  else{

   apache::vhost { 'sugarcrm':
    serveraliases   => '*',
    port            => $apache_http_port,
    docroot         => '/var/www/html/sugarcrm',
    docroot_group   => 'apache',
    docroot_owner   => 'apache',
    docroot_mode    => '755',
    #
    error_log_file  => 'error_log',
    access_log_file => 'access_log',
    #
    custom_fragment => $apache_main_vhost_custom_fragment,
    #
    proxy_pass_match => $proxy_pass_match,
    #
    directories     => $directories_all,
    aliases         => $aliases_phpmyadmin,
   }

  }

  apache::vhost { 'sugarcrm-ssl':
    serveraliases   => '*',
    port            => $apache_https_port,
    docroot         => '/var/www/html/sugarcrm',
    docroot_group   => 'apache',
    docroot_owner   => 'apache',
    docroot_mode    => '755',
    ssl             => true,
    ssl_chain       => $apache_ssl_chain,
    #
    error_log_file  => 'ssl_error_log',
    access_log_file => 'ssl_access_log',
    #
    custom_fragment => $apache_main_vhost_custom_fragment,
    #
    proxy_pass_match => $proxy_pass_match,
    #
    directories     => $directories_all,
    aliases         => $aliases_phpmyadmin,
  }

  if($manage_firewall == true){
    firewall { "100 accept tcp to dport ${apache_https_port}, ${apache_http_port} / APACHE":
        chain   => 'INPUT',
        state   => 'NEW',
        proto   => 'tcp',
        dport   => [$apache_https_port, $apache_http_port],
        action  => 'accept',
    }
  }

  if($manage_sugarcrm_files_ownership == true){
    exec { 'sugarcrm directory2':
      command => '/bin/chown apache:apache /var/www/html/sugarcrm -R',
      require => File['/var/www/html/sugarcrm'],
    }
  }

  if($manage_phpmyadmin_files == true){

    package { 'phpMyAdmin':
      ensure => absent,
    }

    file { '/usr/share/phpMyAdmin':
        ensure  => 'directory',
        mode    => '755',
        owner   => 'root',
        group   => 'root',
        require => Package['phpMyAdmin'],
    }

    vcsrepo { '/usr/share/phpMyAdmin':
      ensure   => present,
      provider => git,
      source   => 'https://github.com/phpmyadmin/phpmyadmin.git',
      revision => $phpmyadmin_files_repo_tag,
      depth    => $phpmyadmin_files_repo_depth,
      user     => 'root',
      require => Package['phpMyAdmin'],
    }

    if ($::sugarcrmstack_ng::sugar_version == '8.0'){
      file { '/usr/share/phpMyAdmin/tmp':
          ensure  => 'directory',
          mode    => '750',
          owner   => 'phpmyadmin',
          group   => 'phpmyadmin',
          require => Vcsrepo['/usr/share/phpMyAdmin'],
      }
    }

    if ! defined (Class['composer']) {
      class { 'composer':
        php_package     => $php_cli_package_name,
        composer_home   => '/root',
        download_method => 'wget',
        auto_update     => false,
        #logoutput       => true,
      }

      composer::exec { 'phpmyadmin-update':
        cmd         => 'update',
        cwd         => '/usr/share/phpMyAdmin',
        dev         => false,
        refreshonly => false,
      }
    }
  }

} #end of class
