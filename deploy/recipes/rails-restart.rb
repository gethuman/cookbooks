#
# Cookbook Name:: deploy
# Recipe:: rails-restart
#

include_recipe "deploy"
instance = search("aws_opsworks_instance", "self:true").first
layers = instance['role']

node[:deploy].each do |application, deploy|
  if deploy[:application_type] != 'rails'
    Chef::Log.debug("Skipping deploy::rails-restart application #{application} as it is not a Rails app")
    next
  end

  execute "restart Server" do
    cwd deploy[:current_path]
    command "sleep #{deploy[:sleep_before_restart]} && #{instance[:rails_stack][:restart_command]}"
    action :run

    only_if do
      File.exists?(deploy[:current_path])
    end
  end

end
