class supramap {
  package { "git" : ensure => present }
  
  $script_home = '/opt/supramap/rci/puppet/supramap/files'
  $ruby_installer = "$script_home/install-ruby.sh"

  $supramap_home = "/opt/supramap/app"
  $ruby_home = "$supramap_home/ruby"
  
  file { "$supramap_home/setup.sh" :
    mode => "0444",
    owner => 'scox',
    group => 'renci',
    source => "$script_home/setup.sh",
  }

  file { $ruby_installer :
    ensure => present,
    owner => 'scox',
    group => 'renci',
    mode => '0755'
  }

  exec { "$ruby_installer $script_home" :
    require => File [ "$ruby_installer" ],
    creates => "$supramap_home/setup.sh"
  }

}


node 'supramap.renci.org' {
    include supramap
}

