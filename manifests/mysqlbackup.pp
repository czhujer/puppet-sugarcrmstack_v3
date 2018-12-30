#
# sub-class for MysqlBackup
#

class sugarcrmstack::mysqlbackup(
  $mysqlbackup_login_user = 'automysqlbackup',
  $mysqlbackup_login_password = '',
  $mysqlbackup_host='localhost',
  $mysqlbackup_backup_dir = '/var/backup/db',
  $mysqlbackup_email = 'infrastruktura-logy@sugarfactory.cz',
  $mysqlbackup_usessl = 'no',
  $mysqlbackup_rotation_daily = 6,
  $mysqlbackup_rotation_weekly = 6,
  $mysqlbackup_rotation_monthly = 28,
  $mysqlbackup_enable_cron_job = true,
){

  file { 'automyqslbackup config dir':
    ensure => 'directory',
    path   => '/etc/automysqlbackup',
    mode   => '0755',
  }

  $automyqslbackup_backup_dir = ['/var/backup', '/var/backup/db']

  file { $automyqslbackup_backup_dir:
	  ensure => 'directory',
    mode  => '0755',
  }

  file { 'automyqslbackup main file':
	  ensure   => file,
	  path     => '/usr/local/bin/automysqlbackup',
    source  => 'puppet:///modules/sugarcrmstack/automysqlbackup/automysqlbackup',
    recurse => true,
    mode    => '0755',
  }

  file { 'automysqlbackup config file':
	  ensure   => file,
	  path     => '/etc/automysqlbackup/localhost.conf',
	  content  => template('sugarcrmstack/automysqlbackup-conf.erb'),
	  owner    => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['automyqslbackup config dir'],
  }

  $automysqlbackup_packages = ['pigz', 'pbzip2', 'mailx' ]

  package { $automysqlbackup_packages:
    ensure => 'installed',
  }

  if($mysqlbackup_enable_cron_job){

    file { '/etc/cron.daily/automysqlbackup':
      ensure => 'link',
	    target  => '/usr/local/bin/automysqlbackup',
	    notify  => Service['cron'],
	    require => File['automyqslbackup main file'],
    }
  }
  else{
    file { '/etc/cron.daily/automysqlbackup':
      ensure => absent,
	    notify  => Service['cron'],
	    require => File['automyqslbackup main file'],
    }
  }
}
