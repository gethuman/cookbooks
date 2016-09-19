template "/tmp/cwlogs.cfg" do
  instance = search("aws_opsworks_instance").first
  variables(
    :host => "#{instance['hostname']}"
  )
  cookbook "logs"
  source "cwlogs.cfg.erb"
  owner "root"
  group "root"
  mode 0644
end
