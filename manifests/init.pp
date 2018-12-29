# Class: sugarcrmstack
# ===========================
#
# Full description of class sugarcrmstack here.
#
# Parameters
# ----------
#
# * `sample parameter`
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
class sugarcrmstack (
  $sugar_version = '7.5'
  ){

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

  notice "This class does nothing.. Use sugarcrmstack_ng or call sub-classes directly..."

}
