#!/usr/bin/perl

#
# Docs
#
# https://github.com/ingydotnet/json-bash
# https://github.com/0k/shyaml
# http://search.cpan.org/~ingy/YAML-Perl-0.02/lib/YAML/Perl.pod
# https://docs.puppetlabs.com/hiera/1/complete_example.html
# https://docs.puppetlabs.com/hiera/1/configuring.html#example-config-file
# http://search.cpan.org/dist/YAML-Tiny/lib/YAML/Tiny.pm
# http://search.cpan.org/~neilb/Crypt-RandPasswd-0.06/lib/Crypt/RandPasswd.pm

use strict;

use YAML::Tiny;

use Crypt::RandPasswd;

use Digest::SHA1 qw(sha1 sha1_hex);

my $gen_pass_min_len = "8";
my $gen_pass_max_len = "8";


#load fqdn
my $facter_fqdn = $ARGV[0];

if ($facter_fqdn eq ""){
  $facter_fqdn = `source /etc/bashrc; facter fqdn 2>/dev/null`;

  #trim whitespaces
  $facter_fqdn =~ s/^\s+|\s+$//g;
}

my $folder = $ARGV[1];
my $file;

if ($folder eq ""){
  $file = "/etc/puppet/hieradata/node--".$facter_fqdn.".yaml";
}
else{
  $file = $folder . "/node--".$facter_fqdn.".yaml";
}

#my $file = "/srv/crm-test6/hiera_data/node--".$facter_fqdn.".yaml";

if (-f $file) {
  print "File Exists..";
} else {
  print "File does not exist..";
  open my $fh, ">>", $file or die "can open file $!";
}

# Open the config
my $yaml = YAML::Tiny->read($file);

# Get a reference to the first document
my $config = $yaml->[0];

#
# read properties directly
#

#zabbixagent
my $zabbixagent_mysql_server_mysql_zabbix_pass = $yaml->[0]->{'zabbixagent::mysql-server::mysql_zabbix_pass'};
my $zabbixagent_mysql_server_mysql_zabbix_pass_hash = $yaml->[0]->{'zabbixagent::mysql-server::mysql_zabbix_pass_hash'};

my $zabbixagent_mysql_server2_mysql_zabbix_pass = $yaml->[0]->{'zabbixagent::mysql_server::mysql_zabbix_pass'};
my $zabbixagent_mysql_server2_mysql_zabbix_pass_hash = $yaml->[0]->{'zabbixagent::mysql_server::mysql_zabbix_pass_hash'};

#sugarcrmstack
my $sugarcrmstack_mysql_root_password = $yaml->[0]->{'sugarcrmstack::mysql_root_password'};
# -only for evidence
my $sugarcrmstack_mysql_sugarcrm_password = $yaml->[0]->{'sugarcrmstack::mysql_sugarcrm_password'};
# -mysql hash, corresponding with password above
my $sugarcrmstack_mysql_sugarcrm_pass_hash = $yaml->[0]->{'sugarcrmstack::mysql_sugarcrm_pass_hash'};
# -infos for databases backup
my $sugarcrmstack_mysql_automysqlbackup_pass_hash = $yaml->[0]->{'sugarcrmstack::mysql_automysqlbackup_pass_hash'};
my $sugarcrmstack_mysqlbackup_mysqlbackup_login_user = $yaml->[0]->{'sugarcrmstack::mysqlbackup::mysqlbackup_login_user'};
# -password for backup user, corresponding with hash above
my $sugarcrmstack_mysqlbackup_mysqlbackup_login_password = $yaml->[0]->{'sugarcrmstack::mysqlbackup::mysqlbackup_login_password'};

my $sugarcrmstack_ng_mysql_server_mysql_automysqlbackup_pass_hash = $yaml->[0]->{'sugarcrmstack_ng::mysql_server_mysql_automysqlbackup_pass_hash'};
my $sugarcrmstack_ng_mysql_server_mysql_root_password = $yaml->[0]->{'sugarcrmstack_ng::mysql_server_mysql_root_password'};
my $sugarcrmstack_ng_mysql_server_mysql_sugarcrm_pass_hash = $yaml->[0]->{'sugarcrmstack_ng::mysql_server_mysql_sugarcrm_pass_hash'};
my $sugarcrmstack_ng_mysql_server_mysql_sugarcrm_password = $yaml->[0]->{'sugarcrmstack_ng::mysql_server_mysql_sugarcrm_password'};

my $sugarcrmstack_back2own_login = $yaml->[0]->{'sugarcrmstack::back2own::login'};
my $sugarcrmstack_back2own_password = $yaml->[0]->{'sugarcrmstack::back2own::password'};
my $sugarcrmstack_back2own_upload_folder = $yaml->[0]->{'sugarcrmstack::back2own::upload_folder'};
my $sugarcrmstack_back2own_upload_folder_dupl = $yaml->[0]->{'sugarcrmstack::back2own::upload_folder_dupl'};

#
# generate content
#
if ( $zabbixagent_mysql_server_mysql_zabbix_pass eq ""
       or
    $zabbixagent_mysql_server_mysql_zabbix_pass eq "xxx_password"
    ){
    print "generating password for element: \n\t \"zabbixagent::mysql_server::mysql_zabbix_pass\"... \t";
    $zabbixagent_mysql_server_mysql_zabbix_pass = Crypt::RandPasswd->chars($gen_pass_min_len, $gen_pass_max_len);

    print $zabbixagent_mysql_server_mysql_zabbix_pass . "\n";

    $yaml->[0]->{'zabbixagent::mysql-server::mysql_zabbix_pass'} = $zabbixagent_mysql_server_mysql_zabbix_pass;
}

if ( $zabbixagent_mysql_server2_mysql_zabbix_pass eq ""
       or
    $zabbixagent_mysql_server2_mysql_zabbix_pass eq "xxx_password"
    ){
    print "inserting password for element: \n\t \"zabbixagent::mysql_server2::mysql_zabbix_pass\"... \t";
    $yaml->[0]->{'zabbixagent::mysql_server::mysql_zabbix_pass'} = $zabbixagent_mysql_server_mysql_zabbix_pass;
}

if ( $zabbixagent_mysql_server_mysql_zabbix_pass_hash eq ""
       or
     $zabbixagent_mysql_server_mysql_zabbix_pass_hash eq "*963DA0EC66FD8B7B223F74BE2EBC53C3EAF487B2"
   ){
    print "generating password for element: \n\t \"zabbixagent::mysql-server::mysql_zabbix_pass_hash\"... \t";
    $zabbixagent_mysql_server_mysql_zabbix_pass_hash = "*".uc(sha1_hex(sha1($zabbixagent_mysql_server_mysql_zabbix_pass)));
    print $zabbixagent_mysql_server_mysql_zabbix_pass_hash . "\n";

    $yaml->[0]->{'zabbixagent::mysql-server::mysql_zabbix_pass_hash'} = $zabbixagent_mysql_server_mysql_zabbix_pass_hash;
}

if ( $zabbixagent_mysql_server2_mysql_zabbix_pass_hash eq ""
       or
     $zabbixagent_mysql_server2_mysql_zabbix_pass_hash eq "*963DA0EC66FD8B7B223F74BE2EBC53C3EAF487B2"
   ){
    print "insering password for element: \n\t \"zabbixagent::mysql_server2::mysql_zabbix_pass_hash\"... \t";
    $yaml->[0]->{'zabbixagent::mysql_server::mysql_zabbix_pass_hash'} = $zabbixagent_mysql_server_mysql_zabbix_pass_hash;
}

if ( $sugarcrmstack_mysql_root_password eq ""
        or
     $sugarcrmstack_mysql_root_password eq "topSecRetPassword"
   ){
    print "generating password for element: \n\t \"sugarcrmstack::mysql_root_password\"... \t";
    $sugarcrmstack_mysql_root_password = Crypt::RandPasswd->chars($gen_pass_min_len, $gen_pass_max_len);
    print $sugarcrmstack_mysql_root_password . "\n";

    $yaml->[0]->{'sugarcrmstack::mysql_root_password'} = $sugarcrmstack_mysql_root_password;
}

if ($sugarcrmstack_ng_mysql_server_mysql_root_password eq ""
      or
    $sugarcrmstack_ng_mysql_server_mysql_root_password eq "topSecRetPassword"
   ){
     print "inserting password for element: \n\t \"sugarcrmstack_ng::mysql_server_mysql_root_password\"... \t";
    $yaml->[0]->{'sugarcrmstack_ng::mysql_server_mysql_root_password'} = $sugarcrmstack_mysql_root_password;
}

if ( $sugarcrmstack_mysql_sugarcrm_password eq ""
        or
     $sugarcrmstack_mysql_sugarcrm_password eq "sugarcrmpassword"
   ){
    print "generating password for element: \n\t \"sugarcrmstack::mysql_sugarcrm_password\"... \t";
    $sugarcrmstack_mysql_sugarcrm_password = Crypt::RandPasswd->chars($gen_pass_min_len, $gen_pass_max_len);
    print $sugarcrmstack_mysql_sugarcrm_password . "\n";

    $yaml->[0]->{'sugarcrmstack::mysql_sugarcrm_password'} = $sugarcrmstack_mysql_sugarcrm_password;
}

if ( $sugarcrmstack_ng_mysql_server_mysql_sugarcrm_password eq ""
      or
     $sugarcrmstack_ng_mysql_server_mysql_sugarcrm_password eq "sugarcrmpassword"
   ){
    print "insering password for element: \n\t \"sugarcrmstack_ng::mysql_server_mysql_sugarcrm_password\"... \t";
    $yaml->[0]->{'sugarcrmstack_ng::mysql_server_mysql_sugarcrm_password'} = $sugarcrmstack_mysql_sugarcrm_password;
}

if ( $sugarcrmstack_mysql_sugarcrm_pass_hash eq ""
        or
     $sugarcrmstack_mysql_sugarcrm_pass_hash eq "*A57E7B25C595673A05CE382D69DBA670AABF7FB4"
   ){
    print "generating hash for element: \n\t \"sugarcrmstack::mysql_sugarcrm_pass_hash\"... \t";
    $sugarcrmstack_mysql_sugarcrm_pass_hash = "*".uc(sha1_hex(sha1($sugarcrmstack_mysql_sugarcrm_password)));
    print $sugarcrmstack_mysql_sugarcrm_pass_hash . "\n";

    $yaml->[0]->{'sugarcrmstack::mysql_sugarcrm_pass_hash'} = $sugarcrmstack_mysql_sugarcrm_pass_hash;
}

if ( $sugarcrmstack_ng_mysql_server_mysql_sugarcrm_pass_hash eq ""
        or
    $sugarcrmstack_ng_mysql_server_mysql_sugarcrm_pass_hash eq "*A57E7B25C595673A05CE382D69DBA670AABF7FB4"
  ){
  print "inserting hash for element: \n\t \"sugarcrmstack_ng::_mysql_server_mysql_sugarcrm_pass_hash\"... \t";
  $yaml->[0]->{'sugarcrmstack_ng::mysql_server_mysql_sugarcrm_pass_hash'} = $sugarcrmstack_mysql_sugarcrm_pass_hash;
}

if ( $sugarcrmstack_mysqlbackup_mysqlbackup_login_user eq "")
{
    print "settings value for element: \n\t \"sugarcrmstack::mysqlbackup_login_user\"... \t";
    $sugarcrmstack_mysqlbackup_mysqlbackup_login_user = "automysqlbackup";
    print $sugarcrmstack_mysqlbackup_mysqlbackup_login_user . "\n";

   $yaml->[0]->{'sugarcrmstack::mysqlbackup::mysqlbackup_login_user'} = $sugarcrmstack_mysqlbackup_mysqlbackup_login_user;
}

if ( $sugarcrmstack_mysqlbackup_mysqlbackup_login_password eq ""
        or
     $sugarcrmstack_mysqlbackup_mysqlbackup_login_password eq "password"
   ){
   print "generating password for element: \n\t \"sugarcrmstack::mysqlbackup_login_password\"... \t";
   $sugarcrmstack_mysqlbackup_mysqlbackup_login_password = Crypt::RandPasswd->chars($gen_pass_min_len, $gen_pass_max_len);
   print $sugarcrmstack_mysqlbackup_mysqlbackup_login_password . "\n";

   $yaml->[0]->{'sugarcrmstack::mysqlbackup::mysqlbackup_login_password'} = $sugarcrmstack_mysqlbackup_mysqlbackup_login_password;
}

if ( $sugarcrmstack_mysql_automysqlbackup_pass_hash eq ""
        or
     $sugarcrmstack_mysql_automysqlbackup_pass_hash eq "*CFD5D603D9CAB79D727124A2BCEF3EF427D63CCC"
   ){
    print "generating hash for element: \n\t \"sugarcrmstack::mysqlbackup_login_pass_hash\"... \t";
    $sugarcrmstack_mysql_automysqlbackup_pass_hash = "*".uc(sha1_hex(sha1($sugarcrmstack_mysqlbackup_mysqlbackup_login_password)));
    print $sugarcrmstack_mysql_automysqlbackup_pass_hash . "\n";

    $yaml->[0]->{'sugarcrmstack::mysql_automysqlbackup_pass_hash'} = $sugarcrmstack_mysql_automysqlbackup_pass_hash;
}

if ( $sugarcrmstack_ng_mysql_server_mysql_automysqlbackup_pass_hash eq ""
        or
     $sugarcrmstack_ng_mysql_server_mysql_automysqlbackup_pass_hash eq "*CFD5D603D9CAB79D727124A2BCEF3EF427D63CCC"
    ){
    print "inserting hash for element: \n\t \"sugarcrmstack::mysql_server_mysql_automysqlbackup_login_pass_hash\"... \t";
    $yaml->[0]->{'sugarcrmstack_ng::mysql_server_mysql_automysqlbackup_pass_hash'} = $sugarcrmstack_mysql_automysqlbackup_pass_hash;
}

if ( $sugarcrmstack_back2own_login eq ""){
    print "generating hash for element: \n\t \"sugarcrmstack::back2own::login\"... \t";
    print $yaml->[0]->{'sugarcrmstack::back2own::login'} = $facter_fqdn . ".sf";
    print "\n";
}

if ( $sugarcrmstack_back2own_password eq "" ){
    print "generating hash for element: \n\t \"sugarcrmstack::back2own::password\"... \t";
    $sugarcrmstack_back2own_password = Crypt::RandPasswd->chars(($gen_pass_min_len+4), ($gen_pass_max_len+4));
    print $yaml->[0]->{'sugarcrmstack::back2own::password'} = $sugarcrmstack_back2own_password;
    print "\n";
}

#if ( $sugarcrmstack_back2own_upload_folder eq "" ){
#    print "generating hash for element: \n\t \"sugarcrmstack::back2own::upload_folder\"... \t";
#    print $yaml->[0]->{'sugarcrmstack::back2own::upload_folder'} = $facter_fqdn . ".sf";
#    print "\n";
#}

if ( $sugarcrmstack_back2own_upload_folder_dupl eq "" ){
    print "generating hash for element: \n\t \"sugarcrmstack::back2own::upload_folder_dupl\"... \t";
    print $yaml->[0]->{'sugarcrmstack::back2own::upload_folder_dupl'} = "/" . $facter_fqdn . ".sf-mount/bc-dupl-" . $facter_fqdn . ".sf";
    print "\n";
}

#writing changes
print "\nwriting changes into file: \"".$file . "\"...\n";
$yaml->write($file);
print "DONE\n";

exit 0;
