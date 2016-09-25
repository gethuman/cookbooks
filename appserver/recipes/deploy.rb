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

directory '/tmp/.ssh' do
  owner 'root'
  group 'root'
  mode '0770'
  recursive true
  action :create
end

template "/tmp/.ssh/chef_ssh_deploy_wrapper.sh" do
  source "chef_ssh_deploy_wrapper.sh.erb"
  owner 'root'
  mode 0770
end


directory '/srv/www/app/current/log' do
  owner 'root'
  group 'root'
  mode '0644'
  recursive true
  action :create
end

git '/srv/www/app/current' do
  repository app['app_source']['url']
  revision "master"
  checkout_branch "master"
  enable_checkout false
  action :sync
  notifies :run, 'execute[npm install]', :immediately
end

execute 'npm install' do
  command "cd /srv/www/app/current && npm install"
  action :nothing
  notifies :run, 'execute[pm2]', :immediately
end

execute 'pm2' do
  command "pm2 startOrRestart /etc/pm2/conf.d/server.json"
end
