
# Override node the version
default['nodejs']['engine'] = 'node'
default['nodejs']['version'] = '4.1.1'
# default['nodejs']['install_method'] = 'binary'

default["nodebin"]["location"] = '/usr/bin/node'
# default["nodebin"]["iojs_location"] = '/usr/local/bin/iojs'
default["nodebin"]["opsworks_location"] = '/usr/local/bin/node'
