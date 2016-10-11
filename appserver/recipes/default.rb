instance = search("aws_opsworks_instance", "self:true").first # this gets the databag for the instance
layers = instance['role'] # the attribute formerly known as 'layers' via opsworks is now found as role in the opsworks instance
app = search("aws_opsworks_app").first
env_var = ""

execute 'add nodejs repo' do
  command 'curl --silent --location https://rpm.nodesource.com/setup_6.x | bash -'
end

yum_package 'nodejs'
package ['gcc-c++', 'make', 'openssl-devel']
yum_package 'ImageMagick'

execute 'install pm2' do
  command 'npm install pm2 -g'
end


# setting environment vars for shell access
if layers.include?("api-layer")
    Chef::Log.info("** setting container to api")
    execute 'add api env var' do
      command 'echo CONTAINER="api" >> /root/.bashrc && export CONTAINER="api"'
    end
elsif layers.include?("web-layer")
    Chef::Log.info("** setting container to web")
    execute 'add web env var' do
      command 'echo CONTAINER="web" >> /root/.bashrc && export CONTAINER="web"'
    end
else
    Chef::Log.info("** setting container to unknown")
    execute 'add unknown env var' do
      command 'echo CONTAINER="unknown" >> /root/.bashrc && export CONTAINER="unknown"'
    end
end

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

directory '/etc/pm2/conf.d' do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
  action :create
  notifies :create, 'file[/root/.ssh/id_rsa]', :immediately
  notifies :create, 'directory[/tmp/.ssh]', :immediately
end

directory '/root/.ssh' do
  owner 'root'
  group 'root'
  recursive true
  action :create
end

file '/root/.ssh/id_rsa' do
  content app['app_source']['ssh_key']
  owner 'root'
  group 'root'
  mode '0600'
  action :create_if_missing
  notifies :touch, 'file[/root/.ssh/known_hosts]', :immediately
end

file '/root/.ssh/known_hosts' do
  owner 'root'
  group 'root'
  action :nothing
  notifies :run, 'execute[genssh]', :immediately
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
  notifies :create, 'directory[/srv/www/app/log]', :immediately
end


directory '/srv/www/app/log' do
  owner 'root'
  group 'root'
  mode '0644'
  recursive true
  action :nothing
  notifies :create, 'directory[/srv/www/app/releases]', :immediately
end

directory '/srv/www/app/releases' do
  owner 'root'
  group 'root'
  mode '0644'
  recursive true
  action :nothing
end
