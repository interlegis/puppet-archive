# extract.pp
/*

== Definition: archive::extract

Archive extractor.

Parameters:

- *$target: Destination directory
- *$src_target: Default value "/usr/src".
- *$root_dir: Default value "".
- *$extension: Default value ".tar.gz".
- *$timeout: Default value 120.
- *$strip_components: Default value 0.

Example usage:

  archive::extract {"apache-tomcat-6.0.26":
    ensure => present,
    target => "/opt",
  }

This means we want to extract the local archive
(maybe downloaded with archive::download)
'/usr/src/apache-tomcat-6.0.26.tar.gz' in '/src/apache-tomcat-6.0.26'

Warning:

The parameter *$root_dir* must be used if the root directory of the archive
is different from the name of the archive *$name*. To extract the name of
the root directory use the commands "tar tf archive.tar.gz" or
"unzip -l archive.zip"

*/

define archive::extract (
  $target,
  $ensure=present,
  $src_target='/usr/src',
  $root_dir='',
  $extension='tar.gz',
  $timeout=120,
  $strip_components) {

  if $root_dir != '' {
    $extract_dir = "${target}/${root_dir}"
  } else {
    $extract_dir = "${target}/${name}"
  }

  case $ensure {
    present: {

      if $extension == 'zip' and $strip_components > 0 {
	 fail ( "Strip components not supported for ZIP archives." )
      }       

      $extract_zip    = "unzip -o ${src_target}/${name}.${extension} -d ${extract_dir}"
      $extract_targz  = "tar --no-same-owner --no-same-permissions --strip-components=${strip_components} -xzf ${src_target}/${name}.${extension} -C ${extract_dir}"
      $extract_tarbz2 = "tar --no-same-owner --no-same-permissions --strip-components=${strip_components} -xjf ${src_target}/${name}.${extension} -C ${extract_dir}"

      exec {"$name unpack":
        command => $extension ? {
          'zip'     => "mkdir -p ${extract_dir} && ${extract_zip}",
          'tar.gz'  => "mkdir -p ${extract_dir} && ${extract_targz}",
          'tgz'     => "mkdir -p ${extract_dir} && ${extract_targz}",
          'tar.bz2' => "mkdir -p ${extract_dir} && ${extract_tarbz2}",
          'tgz2'    => "mkdir -p ${extract_dir} && ${extract_tarbz2}",
          default   => fail ( "Unknown extension value '${extension}'" ),
        },
        creates => $extract_dir,
        timeout => $timeout
      }
    }
    absent: {
      file {$extract_dir:
        ensure  => absent,
        recurse => true,
        purge   => true,
        force   => true,
      }
    }
    default: { err ( "Unknown ensure value: '${ensure}'" ) }
  }
}
