#
# sub-class for backuping into owncloud server
#

class sugarcrmstack::back2own(
$use_full_backups = false,
$use_inc_backups = true,
$handle_cron_job = true,
$cron_job_ensure = link, #used only in full_backups
$cron_inc_job_ensure = present, #used only in inc_backups
$cron_job_hour = "1", #used only in inc_backups
$cron_job_minute = "3", #used only in inc_backups
$login = "",
$password = "",
$upload_folder = "",  #used only in full_backups
$upload_folder_dupl = "", #used only in inc_backups
$dupl_full_if_older_than = "6D",
$dupl_db_archive_folder = "/var/backup/db/daily/sugarcrm",
$dupl_remove_all_but_n_full = "2",
$dupl_timeout = "120",
){

  if($use_full_backups){

    $backup_dir = "/var/backup"

    if ! defined (File[$backup_dir]) {
      file { $backup_dir:
        ensure  => directory,
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
      }
    }

    $back2own_dirs = "/var/backup/sugardata"

    file { $back2own_dirs:
        ensure  => directory,
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
    }

    file { "back2own full script":
        ensure  => present,
        path    => "/root/scripts/back2own-full.sh",
        content => template('sugarcrmstack/back2own-full.sh.erb'),
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
    }

    if($handle_cron_job){

      file { '/etc/cron.daily/back2own-full.sh':
        ensure  => $cron_job_ensure,
	      target  => '/root/scripts/back2own-full.sh',
	      notify  => Service['cron'],
	      require => File["back2own full script"],
      }

    }

  }
  else{
    #old (full) script
    file { "back2own full script":
      ensure => absent,
      path   => "/root/scripts/back2own-full.sh",
    }

    if($handle_cron_job){
      # old (full) link
      file { '/etc/cron.daily/back2own-full.sh':
        ensure => absent,
        notify => Service['cron'],
      }

    }
  }

  if($use_inc_backups){

    if ($::operatingsystemmajrelease in ['7']){
      package{ 'duplicity':
          ensure => installed,
      }
    }
    else {

      $back2own_dupl_deps = ["librsync-devel", "python-devel", "gcc",
                           "python-lockfile", "python-paramiko", "python-GnuPGInterface"]

      package { $back2own_dupl_deps:
        ensure => installed,
      }

      package {'duplicity':
        #bug in pip bacouse https access
        #ensure   => latest,
        ensure   => installed, 
        provider => pip,
        require  => Package[$back2own_dupl_deps],
      }
    }

    $back2own_dupl_cron = "[ -x /root/scripts/back2own-duplicity.sh ] || exit 1 && /root/scripts/back2own-duplicity.sh >> /var/log/back2own-duplicity.log 2>&1"

    if($handle_cron_job){

      cron::job{
        'back2own-duplicity':
          ensure      => $cron_inc_job_ensure,
          minute      => $cron_job_minute,
          hour        => $cron_job_hour,
          date        => '*',
          month       => '*',
          weekday     => '*',
          user        => 'root',
          command     => "${back2own_dupl_cron}\n",
          #environment => "MAILTO=root\nPATH='/usr/bin:/bin'";
          mode        => '0644',
          notify  => Service['cron'],
      }

      # remove old record
      file { '/etc/cron.daily/back2own-duplicity.sh':
        ensure  => absent,
      }

      file { '/etc/cron.daily/back2own-duplicity':
        ensure  => absent,
      }

    }

    file { "back2own duplicity script":
        ensure  => present,
        path    => "/root/scripts/back2own-duplicity.sh",
        content => template('sugarcrmstack/back2own-duplicity.sh.erb'),
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
    }

  }

}
