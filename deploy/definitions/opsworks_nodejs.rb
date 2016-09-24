define :opsworks_nodejs do
  deploy = params[:deploy_data]
  application = params[:app]
  instance = search("aws_opsworks_instance", "self:true").first
  layers = instance['role']

  service 'monit' do
    action :nothing
  end

  node[:dependencies][:npms].each do |npm, version|
    execute "/usr/local/bin/npm install #{npm}" do
      cwd "#{deploy[:deploy_to]}/current"
    end
  end


  file "#{deploy[:deploy_to]}/shared/config/ssl.crt" do
    owner deploy[:user]
    mode 0600
    content deploy[:ssl_certificate]
    only_if do
      deploy[:ssl_support]
    end
  end

  file "#{deploy[:deploy_to]}/shared/config/ssl.key" do
    owner deploy[:user]
    mode 0600
    content deploy[:ssl_certificate_key]
    only_if do
      deploy[:ssl_support]
    end
  end

  file "#{deploy[:deploy_to]}/shared/config/ssl.ca" do
    owner deploy[:user]
    mode 0600
    content deploy[:ssl_certificate_ca]
    only_if do
      deploy[:ssl_support] && deploy[:ssl_certificate_ca].present?
    end
  end
end
