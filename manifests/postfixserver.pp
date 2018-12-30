
class sugarcrmstack::postfixserver (
$postfix_server_enable='1',
$postfix_server_fqdn = '',
$postfix_service_enable = true,
$postfix_service_ensure = true,
$sugar_version = $sugarcrmstack::sugar_version,
) {

  #variables check
  if $sugar_version == undef {
    warning "Missing variable \"sugar_version\""
    fail('exiting...')
  }

  if $postfix_server_fqdn == undef{
     $my_fqdn = $::fqdn
     $postfix_server_fqdn_final = "${my_fqdn}.sugarfactory.cz"
  }
  else{
     $postfix_server_fqdn_final = $postfix_server_fqdn
  }

  if str2bool($postfix_server_enable){

    $packages_sendmail = ['sendmail-cf', 'sendmail' ]

    package { $packages_sendmail:
        ensure => absent,
    }

    package {'postfix':
         ensure => installed,
         require => Package[$packages_sendmail],
    }

    service {'postfix':
         ensure  => $postfix_service_ensure,
         enable  => $postfix_service_enable,
         require => Package['postfix'],
         subscribe => [
            Ini_setting['postfix conf myorigin'],
            Ini_setting['postfix conf myhostname'],
         ]
    }

    ini_setting { 'postfix conf myorigin':
        ensure  => present,
        path    => '/etc/postfix/main.cf',
        section => '',
        setting => 'myorigin',
        value   => '$myhostname',
        require => Package['postfix'],
    }

    ini_setting { 'postfix conf myhostname':
        ensure  => present,
        path    => '/etc/postfix/main.cf',
        section => '',
        setting => 'myhostname',
        value   => $postfix_server_fqdn_final,
        require => Package['postfix'],
    }

  } #end of if str2bool($postfix_server_enable)
  else{
    warning 'Postfix-server is disable'
  }

} #end of class
