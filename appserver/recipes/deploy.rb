app = search("aws_opsworks_app").first
instance = search("aws_opsworks_instance", "self:true").first # this gets the databag for the instance
layers = instance['role'] # the attribute formerly known as 'layers' via opsworks is now found as role in the opsworks instance
env_var = ""
release = Time.now.strftime("%Y%m%d%H%M")

git "/srv/www/app/releases/#{release}" do
  repository app['app_source']['url']
  ssh_wrapper "/tmp/.ssh/chef_ssh_deploy_wrapper.sh"
  revision "master"
  checkout_branch "master"
  enable_checkout false
  action :run
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
  notifies :run, 'execute[unlink current]', :immediately
end

execute 'unlink current' do
  command "/bin/unlink /srv/www/app/current"
  action :nothing
  notifies :run, 'execute[link release]', :immediately
end

execute 'link release' do
  command "/bin/ln -s /srv/www/app/releases/#{release} /srv/www/app/current"
  action :nothing
  notifies :run, 'execute[pm2]', :immediately
end

execute 'pm2' do
  command "pm2 startOrRestart /etc/pm2/conf.d/server.json"
  action :nothing
end
