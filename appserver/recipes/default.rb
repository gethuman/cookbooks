instance = search("aws_opsworks_instance", "self:true").first # this gets the databag for the instance
layers = instance['role'] # the attribute formerly known as 'layers' via opsworks is now found as role in the opsworks instance
app = search("aws_opsworks_app").first
env_var = ""

execute 'add nodejs repo' do
  command 'curl --silent --location https://rpm.nodesource.com/setup_12.x | bash -'
end

yum_package 'nodejs'
package ['gcc-c++', 'make', 'openssl-devel', 'perl-Switch', 'perl-DateTime', 'perl-Sys-Syslog', 'perl-LWP-Protocol-https']
yum_package 'ImageMagick'

if layers.include?("api-layer") || layers.include?("web-layer") || layers.include?("freeswitch-layer") || layers.include?("robocall-layer")
  execute 'install pm2' do
    command 'npm install pm2 -g'
  end
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
elsif layers.include?("batch-layer")
    Chef::Log.info("** setting container to batch")
    execute 'add batch env var' do
      command 'echo CONTAINER="batch" >> /root/.bashrc && export CONTAINER="batch"'
    end
elsif layers.include?("freeswitch-layer")
    Chef::Log.info("** setting container to freeswitch")
    execute 'add freeswitch env var' do
      command 'echo CONTAINER="batch" >> /root/.bashrc && export CONTAINER="freeswitch"'
    end
elsif layers.include?("robocall-layer")
    Chef::Log.info("** setting container to robocall")
    execute 'add robocall env var' do
      command 'echo CONTAINER="batch" >> /root/.bashrc && export CONTAINER="robocall"'
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
elsif layers.include?("batch-layer")
    env_var = env_var + '"CONTAINER":"batch"'
elsif layers.include?("freeswitch-layer")
    env_var = env_var + '"CONTAINER":"freeswitch"'
elsif layers.include?("robocall-layer")
    env_var = env_var + '"CONTAINER":"robocall"'
else
    env_var = env_var + '"CONTAINER":"unknown"'
end

if layers.include?("api-layer") || layers.include?("web-layer") || layers.include?("freeswitch-layer") || layers.include?("robocall-layer")
  directory '/etc/pm2/conf.d' do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
    notifies :create, 'file[/root/.ssh/id_rsa]', :immediately
    notifies :create, 'directory[/tmp/.ssh]', :immediately
  end
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

remote_file "/tmp/CloudWatchMonitoringScripts-1.2.1.zip" do
  source "http://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.1.zip"
  owner "root"
  group "root"
  mode 0750
  action :create_if_missing
end

execute "unzip cloud watch monitoring scripts" do
  command "unzip /tmp/CloudWatchMonitoringScripts-1.2.1.zip"
  cwd "/root"
  user "root"
  group "root"
end

cron "cloudwatch_schedule_metrics" do
  action :create
  minute "*/5"
  user "root"
  command "/root/aws-scripts-mon/mon-put-instance-data.pl --mem-util --disk-space-util --disk-path=/ --from-cron"
end

file '/etc/cron.hourly/logrotate' do
  mode 0755
  owner 'root'
  group 'root'
  content '#!/bin/sh
   /usr/sbin/logrotate /etc/logrotate.conf >/dev/null 2>&1
   EXITVALUE=$?
   if [ $EXITVALUE != 0 ]; then
       /usr/bin/logger -t logrotate "ALERT exited abnormally with [$EXITVALUE]"
   fi
   exit 0'
 end