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
  notifies :create, 'template[/etc/pm2/conf.d/server.json]', :immediately
end

template '/etc/pm2/conf.d/server.json' do
  source 'server.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables :environments => { 'vars' => env_var }
  action :nothing
  notifies :create, 'file[/root/.ssh/id_rsa]', :immediately
  notifies :create, 'directory[/tmp/.ssh]', :immediately
end

directory '/root/.ssh' do
  owner 'root'
  group 'root'
  recursive true
  action :create
end

file '/root/.ssh/known_hosts' do
  owner 'root'
  group 'root'
  action :nothing
  notifies :run, 'execute[genssh]', :immediately
end

file '/root/.ssh/id_rsa' do
  content app['app_source']['ssh_key']
  owner 'root'
  group 'root'
  mode '0600'
  action :create_if_missing
  notifies :touch, 'file[/root/.ssh/known_hosts]', :immediately
end

execute 'genssh' do
  command "ssh-keygen -R bitbucket.org"
  action :nothing
  notifies :run, 'execute[add_known_hosts]', :immediately
end

execute 'add_known_hosts' do
  command "ssh-keyscan -H bitbucket.org >> /root/.ssh/known_hosts"
  action :nothing
  notifies :create, 'directory[/tmp/.ssh]', :immediately
end

directory '/tmp/.ssh' do
  owner 'root'
  group 'root'
  mode '0770'
  recursive true
  action :nothing
  notifies :create, 'template[/tmp/.ssh/chef_ssh_deploy_wrapper.sh]', :immediately
  notifies :create, 'file[/root/.ssh/id_rsa]', :immediately
end

template "/tmp/.ssh/chef_ssh_deploy_wrapper.sh" do
  source "chef_ssh_deploy_wrapper.sh.erb"
  owner 'root'
  mode 0770
  action :nothing
  notifies :create, 'directory[/srv/www/app/current]', :immediately
end


directory '/srv/www/app/current' do
  owner 'root'
  group 'root'
  mode '0644'
  recursive true
  action :nothing
  notifies :create, 'directory[/srv/www/app/log]', :immediately
end

directory '/srv/www/app/log' do
  owner 'root'
  group 'root'
  mode '0644'
  recursive true
  action :nothing
  notifies :sync, 'git[/srv/www/app/current]', :immediately
end


git '/srv/www/app/current' do
  repository app['app_source']['url']
  ssh_wrapper "/tmp/.ssh/chef_ssh_deploy_wrapper.sh"
  revision "master"
  checkout_branch "master"
  enable_checkout false
  action :nothing
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
