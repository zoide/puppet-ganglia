define ganglia::module::python_git (
		$ensure           = 'present',
		$conf_replace     = false,
		$install_packages = false,
		$pyconf           = $name,
		$creates          = false) {
	include 'ganglia::params'
		require 'git::client'

		if $conf_replace != false {
			validate_hash($conf_replace)
		}

	if $install_packages != false and $ensure == 'present' {
		package { $install_packages: }
	}

	Exec {
		notify => Service[$ganglia::params::gmond], }

	if $ensure == 'present' {
		exec { "copy-pyconf_${name}":
			command => "cp ${ganglia::params::git_mods}/${name}/conf.d/${pyconf}.pyconf ${ganglia::params::conf_d}/${name}.pyconf",
			creates => "${ganglia::params::conf_d}/${name}.pyconf",
		}
	} else {
		exec { "rm-pyconf_${name}":
			command => "rm ${ganglia::params::conf_d}/${name}.pyconf",
				onlyif  => "test -e ${ganglia::params::conf_d}/${name}.pyconf",
		}
	}

	$creates_real = $creates ? {
		false   => "${name}.py",
			default => $creates,
	}

	exec { "enable-gmond-git-${name}":
		command => "ln -sf ${ganglia::params::git_mods}/${name}/python_modules/* .",
			creates => "/usr/lib/ganglia/python_modules/${creates_real}",
			cwd     => '/usr/lib/ganglia/python_modules'
	}

	if $ensure == 'present' and $conf_replace != false {
		common::replace { "conf-replace-${name}":
			file        => "${ganglia::params::conf_d}/${name}.pyconf",
				    pattern     => $conf_replace['pattern'],
				    replacement => $conf_replace['replacement'],
				    require     => Exec["copy-pyconf_${name}"],
		}
	}
}
