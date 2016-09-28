app = search("aws_opsworks_app").first
instance = search("aws_opsworks_instance", "self:true").first # this gets the databag for the instance
layers = instance['role'] # the attribute formerly known as 'layers' via opsworks is now found as role in the opsworks instance
env_var = ""

app['environment'].each do |key,value|
  env_var = env_var << "\"#{key}\":\"#{value}\","
end

if layers.include?("api-layer")
    env_var = env_var + '"CONTAINER":"api"'
elsif layers.include?("web-layer")
    env_var = env_var + '"CONTAINER":"web"'
else
    env_var = env_var + '"CONTAINER":"unknown"'
end


git '/srv/www/app/current' do
  repository app['app_source']['url']
  ssh_wrapper "/tmp/.ssh/chef_ssh_deploy_wrapper.sh"
  revision "master"
  checkout_branch "master"
  enable_checkout false
  action :sync
  notifies :run, 'execute[app perms]', :immediately
end

execute 'app perms' do
  command "chown -R root:root /srv/www/app/current"
  action :nothing
  notifies :run, 'execute[set file perms]', :immediately
end

execute 'set file perms' do
  command "setfacl -Rdm g:root:rwx /srv/www/app/current"
  action :nothing
  notifies :run, 'execute[npm install]', :immediately
end

execute 'npm install' do
  command "su - root -c 'cd /srv/www/app/current && npm install'"
  action :nothing
  notifies :run, 'execute[pm2]', :immediately
end

execute 'pm2' do
  command "pm2 startOrRestart /etc/pm2/conf.d/server.json"
  action :nothing
end
