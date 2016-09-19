template "/tmp/cwlogs.cfg" do
  instance = search("aws_opsworks_instance").first
  stack = search("aws_opsworks_stack").first
  variables(
    :host      => "#{instance['hostname']}",
    :stackname => "#{stack['name']}"
  )
  cookbook "logs"
  source "cwlogs.cfg.erb"
  owner "root"
  group "root"
  mode 0644
end
