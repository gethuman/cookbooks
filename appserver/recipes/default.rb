execute 'add nodejs repo' do
  command 'curl --silent --location https://rpm.nodesource.com/setup_6.x | bash -'
end

yum_package 'nodejs'
package ['gcc-c++', 'make']
yum_package 'ImageMagick'

execute 'install pm2' do
  command 'npm install pm2 -g'
end
