pkg_origin=jam
pkg_name=remotedocker
pkg_version=0.0.1
pkg_maintainer="Jam <dont@email.me>"
pkg_license=()
pkg_upstream_url=https://gitlab.com/spaz/docker-remote-saver
pkg_source=nosuchfile.tar.gz
pkg_build_deps=( core/gcc core/make )
pkg_deps=( core/bundler )
pkg_exports=( [port]=listening_port )
pkg_exposes=(port)

do_download() {
  return 0
}

do_verify() {
  return 0
}

do_unpack() {
  return 0
}

do_build() {
  # Copy contents of the source directory into your $HAB_CACHE_SRC_PATH/$pkg_dirname as this 
  # is the same path that Habitat would use if you downloaded a tarball of the source code.
  cp -vr $PLAN_CONTEXT/../* $HAB_CACHE_SRC_PATH/$pkg_dirname

  # This installs dependent gems
  bundle install --path="$HAB_CACHE_SRC_PATH/$pkg_dirname/vendor/cache" --without test
}

do_install() {
  # Our source files were copied over to HAB_CACHE_SRC_PATH/$pkg_dirname in do_build(),
  # and now they need to be copied from that directory into the root directory of our package 
  # through the use of the pkg_prefix variable. 
  cp Gemfile ${pkg_prefix}
  cp Gemfile.lock ${pkg_prefix}
  cp error.html ${pkg_prefix}
  cp help.html ${pkg_prefix}
  cp server.rb ${pkg_prefix}

  # Copy over the gems that we installed in do_build().
  mkdir -p ${pkg_prefix}/vendor/cache
  cp -vr vendor/cache/* ${pkg_prefix}/vendor/cache
}
