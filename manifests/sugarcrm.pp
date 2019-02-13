#
# web sugarcrm part
#

class sugarcrmstack::sugarcrm(
$changing_perm_for_custom_dir='1',
$git_hooks_support='0',
$git_hooks_template='default',
){

  # logrotate config for sugar-cron
  file { 'logrotate config for sugar-cron':
    ensure  => present,
    path    => '/etc/logrotate.d/sugarcrm-cron',
    content => template('sugarcrmstack/logrotate.conf.sugarcrm-cron.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  file {'sugarcrm config file':
    ensure  => present,
    path    => '/var/www/html/sugarcrm/config.php',
    mode    => '0664',
    owner   => 'apache',
    group   => 'apache',
    require => [
#	         File['sugarcrm directory'],
      Exec['sugarcrm directory2'],
    ],
  }

  file {'sugarcrm config file2':
    ensure  => present,
    path    => '/var/www/html/sugarcrm/config_override.php',
    mode    => '0644',
    owner   => 'apache',
    group   => 'apache',
    require => [
#                File['sugarcrm directory'],
      Exec['sugarcrm directory2'],
    ],
  }

  file {'sugarcrm htacces file':
    ensure  => present,
    path    => '/var/www/html/sugarcrm/.htaccess',
    mode    => '0644',
    owner   => 'apache',
    group   => 'apache',
    require => [
#                 File['sugarcrm directory'],
      Exec['sugarcrm directory2'],
    ],
  }

  file {'sugarcrm _sf_git folder':
    ensure  => 'directory',
    path    => '/var/www/html/sugarcrm/_sf_git',
    mode    => '0755',
    owner   => 'apache',
    group   => 'apache',
    require => [
#                File['sugarcrm directory'],
      Exec['sugarcrm directory2'],
    ],
  }

  file {'sugarcrm _sf_git-scripts folder':
    ensure  => 'directory',
    path    => '/var/www/html/sugarcrm/_sf_git/scripts',
    mode    => '0755',
    owner   => 'apache',
    group   => 'apache',
    require => [
#                File['sugarcrm directory'],
      Exec['sugarcrm directory2'],
    ],
  }

  file {'sugarcrm _sf_git htaccess file':
    ensure  => 'present',
    path    => '/var/www/html/sugarcrm/_sf_git/.htaccess',
    content => 'deny from all',
    mode    => '0644',
    owner   => 'apache',
    group   => 'apache',
    require => [
#                File['sugarcrm directory'],
      Exec['sugarcrm directory2'],
      File['sugarcrm _sf_git folder'],
    ],
  }

  file {'sugarcrm install test file':
    ensure  => 'present',
    path    => '/var/www/html/sugarcrm/install_test.txt',
    mode    => '0644',
    owner   => 'apache',
    group   => 'apache',
    require => [
#                File['sugarcrm directory'],
      Exec['sugarcrm directory2'],
    ],
  }

  if str2bool($changing_perm_for_custom_dir){

    $sugarcrm_folders1 = ['/var/www/html/sugarcrm/custom',
                      '/var/www/html/sugarcrm/cache',
                      '/var/www/html/sugarcrm/upload',
                      '/var/www/html/sugarcrm/modules',
    ]
  }
  else{

    $sugarcrm_folders1 = [
                      '/var/www/html/sugarcrm/cache',
                      '/var/www/html/sugarcrm/upload',
                      '/var/www/html/sugarcrm/modules',
    ]
  }

  file { $sugarcrm_folders1:
    ensure  => 'directory',
    owner   => 'apache',
    group   => 'apache',
#    mode   =>  0775,
    require => [
#                File['sugarcrm directory'],
      Exec['sugarcrm directory2'],
    ],
  }

  exec { 'sugar f basic perms':
    command => '/bin/find /var/www/html/sugarcrm -type f -exec chmod 644 {} \; ',
    before  => [
      File[$sugarcrm_folders1],
    ],
    require => [
    #               File['sugarcrm directory'],
      Exec['sugarcrm directory2'],
    ],
  }

  exec { 'sugar d basic perms':
    command => '/bin/find /var/www/html/sugarcrm -type d -exec chmod 755 {} \; ',
    before  => File[$sugarcrm_folders1],
    require => [
    #               File['sugarcrm directory'],
      Exec['sugarcrm directory2'],
    ],
  }

  exec { 'sugar f cache perms':
    command => '/bin/find /var/www/html/sugarcrm/cache/ -type d -exec chmod 0775 {} \; ',
    require => File[$sugarcrm_folders1],
  }

  exec { 'sugar f custom perms':
    command => '/bin/find /var/www/html/sugarcrm/custom/ -type d -exec chmod 0775 {} \; ',
    require => File[$sugarcrm_folders1],
  }

  exec { 'sugar f upload perms':
    command => '/bin/find /var/www/html/sugarcrm/upload/ -type d -exec chmod 0775 {} \; ',
    require => File[$sugarcrm_folders1],
  }

  exec { 'sugar f modules perms':
    command => '/bin/find /var/www/html/sugarcrm/modules/ -type d -exec chmod 0775 {} \; ',
    require => File[$sugarcrm_folders1],
  }

  if str2bool ($git_hooks_support){

    $sugarcrm_git_folders = [
      '/var/www/html/sugarcrm/.git',
      '/var/www/html/sugarcrm/.git/hooks',
    ]

    file { $sugarcrm_git_folders:
      ensure  => 'directory',
      mode    => '0755',
      require => [
#                File['sugarcrm directory'],
        Exec['sugarcrm directory2'],
      ],
    }

    file { "sugarcrm git hook precommit ${git_hooks_template}":
      ensure  => present,
      path    => '/var/www/html/sugarcrm/.git/hooks/pre-commit',
      content => template("sugarcrmstack/git_hook_pre-commit-${git_hooks_template}.erb"),
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => [
        File[$sugarcrm_git_folders],
        Exec['sugar f basic perms'],
      ],
    }

    file { "sugarcrm git hook postcheckout ${git_hooks_template}":
      ensure  => present,
      path    => '/var/www/html/sugarcrm/.git/hooks/post-checkout',
      content => template("sugarcrmstack/git_hook_post-checkout-${git_hooks_template}.erb"),
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => [
        File[$sugarcrm_git_folders],
        Exec['sugar f basic perms'],
      ],
    }

    #links for backward compatibility
    file { '/var/www/html/sugarcrm/_sf_git/scripts/pre-commit.sh':
      ensure  => 'link',
      target  => '/var/www/html/sugarcrm/.git/hooks/pre-commit',
      require => File['sugarcrm _sf_git-scripts folder'],
    }

    file { '/var/www/html/sugarcrm/_sf_git/scripts/post-checkout.sh':
      ensure  => 'link',
      target  => '/var/www/html/sugarcrm/.git/hooks/post-checkout',
      require => File['sugarcrm _sf_git-scripts folder'],
    }

  } #end if git_hooks_support

}
