app = search("aws_opsworks_app").first
instance = search("aws_opsworks_instance", "self:true").first # this gets the databag for the instance
layers = instance['role'] # the attribute formerly known as 'layers' via opsworks is now found as role in the opsworks instance
env_var = app['environment'].to_s

if layers.include?("api-layer")
    env_var = env_var + ',"CONTAINER":"api"'
elsif layers.include?("web-layer")
    env_var = env_var + ',"CONTAINER":"web"'
else
    env_var = env_var + ',"CONTAINER":"unknown"'
end

directory '/etc/pm2/conf.d' do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
  action :create
end

template '/etc/pm2/conf.d/server.json' do
  source 'server.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables :environments => { 'vars' => env_var }
end

file '/root/.ssh/id_rsa' do
  content app['app_source']['ssh_key']
  owner 'root'
  group 'root'
  mode '0600'
end

deploy 'private_repo' do
  repo app['app_source']['url']
  migrate false
  keep_releases 5
  symlink_before_migrate({})
  restart_command "cd /srv/www/app/current && npm install && pm2 startOrRestart /etc/pm2/conf.d/server.json"
  user 'root'
  deploy_to '/srv/www/app'
  action :deploy
end
