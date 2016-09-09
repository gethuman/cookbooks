#
# Cookbook Name:: pm2
# Attributes:: default
#
# Copyright 2015, Mindera
#
default_unless['pm2']['version'] = 'latest'

# set value for env vars  node[:deploy]['app'][:environment_variables]

layers = node[:opsworks][:instance][:layers]

if layers.include?("api-layer")
    Chef::Log.info("** setting container to api")
    normal[:deploy]["app"][:environment_variables]["CONTAINER"] = "api"
elsif layers.include?("web-layer")
    Chef::Log.info("** setting container to web")
    normal[:deploy]["app"][:environment_variables]["CONTAINER"] = "web"
else
    Chef::Log.info("** setting container to unknown")
    normal[:deploy]["app"][:environment_variables]["CONTAINER"] = "unknown"
end
