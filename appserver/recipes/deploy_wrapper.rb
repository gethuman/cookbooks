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
end
