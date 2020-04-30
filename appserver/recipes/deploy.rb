app = search("aws_opsworks_app").first
instance = search("aws_opsworks_instance", "self:true").first # this gets the databag for the instance
layers = instance['role'] # the attribute formerly known as 'layers' via opsworks is now found as role in the opsworks instance
release = Time.now.strftime("%Y%m%d%H%M")
env_var = ""

# building environment vars
app['environment'].each do |key,value|
  env_var = env_var << "\"#{key}\":\"#{value}\","
end

if layers.include?("api-layer")
    env_var = env_var + '"CONTAINER":"api"'
elsif layers.include?("web-layer")
    env_var = env_var + '"CONTAINER":"web"'
elsif layers.include?("batch-layer")
    env_var = env_var + '"CONTAINER":"batch"'
else
    env_var = env_var + '"CONTAINER":"unknown"'
end

include_recipe 'appserver::deploy_wrapper'

if layers.include?("api-layer") || layers.include?("web-layer")
  git "/srv/www/app/releases/#{release}" do
    repository app['app_source']['url']
    ssh_wrapper "/tmp/.ssh/chef_ssh_deploy_wrapper.sh"
    revision app['app_source']['revision'] ? app['app_source']['revision'] : "master"
    checkout_branch app['app_source']['revision'] ? app['app_source']['revision'] : "master"
    enable_checkout false
    action :sync
    notifies :create, 'template[/etc/pm2/conf.d/server.json]', :immediately
    notifies :run, 'execute[app perms]', :immediately
    notifies :run, 'execute[set file perms]', :immediately
    notifies :run, 'execute[npm install]', :immediately
    notifies :create, 'link[/srv/www/app/current]', :immediately
    notifies :run, 'execute[pm2]', :immediately
  end

  template '/etc/pm2/conf.d/server.json' do
    source 'server.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables :environments => { 'vars' => env_var }
    action :nothing
  end
else
  git "/srv/www/app/releases/#{release}" do
    repository app['app_source']['url']
    ssh_wrapper "/tmp/.ssh/chef_ssh_deploy_wrapper.sh"
    revision app['app_source']['revision'] ? app['app_source']['revision'] : "master"
    checkout_branch app['app_source']['revision'] ? app['app_source']['revision'] : "master"
    enable_checkout false
    action :sync
    notifies :run, 'execute[app perms]', :immediately
    notifies :run, 'execute[set file perms]', :immediately
    notifies :run, 'execute[npm install]', :immediately
    notifies :create, 'link[/srv/www/app/current]', :immediately
  end
end

execute 'app perms' do
  command "chown -R root:root /srv/www/app/releases/#{release}"
  action :nothing
end

execute 'set file perms' do
  command "setfacl -Rdm g:root:rwx /srv/www/app/releases/#{release}"
  action :nothing
end

execute 'npm install' do
  command "su - root -c 'cd /srv/www/app/releases/#{release} && npm install'"
  action :nothing
end

link '/srv/www/app/current' do
  to "/srv/www/app/releases/#{release}"
  link_type :symbolic
  action :nothing
end

if layers.include?("api-layer") || layers.include?("web-layer")
  execute 'pm2' do
    command "pm2 startOrRestart /etc/pm2/conf.d/server.json"
    command "pm2 install pm2-logrotate"
    command "pm2 set pm2-logrotate:max_size 1K"
    command "pm2 set pm2-logrotate:retain 10"
    command "pm2 startOrRestart /etc/pm2/conf.d/server.json"
    action :nothing
  end
end

janitor_sweep '/srv/www/app/releases' do		
  action :purge		
  directory_size "8K" # each release directory is 4K block size, so 4K * x releases to keep
end

janitor_sweep '/srv/www/app/log' do		
  action :purge		
  directory_size "8K" # each release directory is 4K block size, so 4K * x releases to keep
end 