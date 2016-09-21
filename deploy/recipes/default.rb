include_recipe 'dependencies'

node[:deploy].each do |application, deploy|
  override['infrastructure_class'] = 'ec2'
  opsworks_deploy_user do
    deploy_data deploy
  end

end
