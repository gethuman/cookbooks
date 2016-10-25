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
else
    env_var = env_var + '"CONTAINER":"unknown"'
end

directory '/tmp/.ssh' do
  owner 'root'
  group 'root'
  mode '0770'
  recursive true
  action :create
  notifies :create, 'template[/tmp/.ssh/chef_ssh_deploy_wrapper.sh]', :immediately
end

template "/tmp/.ssh/chef_ssh_deploy_wrapper.sh" do
  source "chef_ssh_deploy_wrapper.sh.erb"
  owner 'root'
  mode 0770
  action :nothing
  notifies :sync, "git[/srv/www/app/releases/#{release}]", :immediately
end

git "/srv/www/app/releases/#{release}" do
  repository app['app_source']['url']
  ssh_wrapper "/tmp/.ssh/chef_ssh_deploy_wrapper.sh"
  revision "master"
  checkout_branch "master"
  enable_checkout false
  action :nothing
  notifies :create, 'template[/etc/pm2/conf.d/server.json]', :immediately
end

template '/etc/pm2/conf.d/server.json' do
  source 'server.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables :environments => { 'vars' => env_var }
  action :nothing
  notifies :run, 'execute[app perms]', :immediately
end

execute 'app perms' do
  command "chown -R root:root /srv/www/app/releases/#{release}"
  action :nothing
  notifies :run, 'execute[set file perms]', :immediately
end

execute 'set file perms' do
  command "setfacl -Rdm g:root:rwx /srv/www/app/releases/#{release}"
  action :nothing
  notifies :run, 'execute[npm install]', :immediately
end

execute 'npm install' do
  command "su - root -c 'cd /srv/www/app/releases/#{release} && npm install'"
  action :nothing
  notifies :create, 'link[/srv/www/app/current]', :immediately
end

link '/srv/www/app/current' do
  to "/srv/www/app/releases/#{release}"
  link_type :symbolic
  action :nothing
  notifies :run, 'execute[pm2]', :immediately
end

execute 'pm2' do
  command "pm2 startOrRestart /etc/pm2/conf.d/server.json"
  action :nothing
end
