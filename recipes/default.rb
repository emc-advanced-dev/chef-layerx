#
# Cookbook Name:: layerx
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
# Cross-platform way of finding an executable in the $PATH.
#
#   which('ruby') #=> /usr/bin/ruby

# dependent recipes
include_recipe 'apt'
include_recipe 'golang'
if node['layerx']['deploy_marathon']
  include_recipe 'java'
end

# install make if not available
apt_package 'make' do
  action :install
end

gopath = '/opt/go'
repo_dir = "#{gopath}/src/github.com/emc-advanced-dev"
layerx_path = "#{repo_dir}/layerx"

user = node['layerx']['user']
group = node['layerx']['group']

directory "#{repo_dir}" do
  action :create
  mode 0755
  recursive true
  owner user
  group group
end

#Clone LayerX from github
git layerx_path do
  repository 'git://github.com/emc-advanced-dev/layerx.git'
  reference 'master'
  action :sync
  user user
  group 
end


# Validate go is installed
bash 'build_layerx' do
  env = Hash.new
  ENV.each do |key, val|
    env[key] = val
  end
  # make & put binaries into path
  cwd layerx_path
  environment env
  code <<-EOH
    echo "MY ENV:"
    env
    echo "BUILDING LAYER-X ALL BINARIES"
    echo $PATH
    echo #{ENV['PATH']}
    export PATH=#{ENV['PATH']}:#{gopath}/bin:/usr/local/go/bin:/opt/go/bin
    export GOPATH=#{gopath}
    make
    sudo cp -r #{layerx_path}/bin/* /usr/local/bin/
  EOH
  only_if LayerxHelper::in_path?('go') && LayerxHelper::in_path?('go-bindata') && LayerxHelper::in_path?('go-bindata-assetfs')
  user user
  group group
end

logs_dir = "/var/log/layerx"

directory "#{logs_dir}" do
  action :create
  mode 0755
  recursive true
  owner user
  group group
end


etcd_installation_binary 'default' do
  action :create
end

etcd_service_manager_execute 'default' do
  action :start
end

# Launch Layer-X
bash 'run_layerx' do
  code <<-EOH
    echo "STARTING LAYERX CORE"
    nohup layerx-core > #{logs_dir}/core.log 2>&1 &
    sleep 2
    echo "STARTING MESOS TPI"
    nohup layerx-mesos-tpi -layerx #{node['ipaddress']}:5000 -localip #{node['ipaddress']} > #{logs_dir}/mesos_tpi.log 2>&1 &
  EOH
  only_if (LayerxHelper::in_path?('layerx-core') && LayerxHelper::in_path?('layerx-mesos-tpi'))
  user user
  group group
end

bash 'install & run marathon' do
  code <<-EOH
    sudo service marathon stop #in case it's running
    echo "DOWNLOADING MARATHON BINARY"
    curl -O http://downloads.mesosphere.com/marathon/v1.1.1/marathon-1.1.1.tgz && tar xzf marathon-1.1.1.tgz
    echo "STARTING MARATHON"
    sleep 30 #wait for zookeeper to be ready?
    nohup marathon-1.1.1/bin/start --master #{node['ipaddress']}:3000 --task_launch_confirm_timeout 1200000 --task_launch_timeout 1200000 > #{logs_dir}/marathon.log 2>&1 &
  EOH
  cwd "/home/#{user}"
  only_if (node['layerx']['deploy_marathon'] && LayerxHelper::in_path?('layerx-core') && LayerxHelper::in_path?('layerx-mesos-tpi'))
  user user
  group group
end
