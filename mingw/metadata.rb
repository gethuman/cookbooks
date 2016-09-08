name 'mingw'
maintainer 'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license 'Apache 2.0'
description 'Installs a mingw/msys based toolchain on windows'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '1.2.4'

supports 'windows'

depends 'seven_zip'
depends 'compat_resource'

source_url 'https://github.com/chef-cookbooks/mingw'
issues_url 'https://github.com/chef-cookbooks/mingw/issues'
