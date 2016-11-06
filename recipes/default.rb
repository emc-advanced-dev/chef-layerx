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
    export PATH=#{ENV['PATH']}:#{gopath}/bin:/usr/local/go/bin:/opt/go/bin:#{layerx_path}/bin
    export GOPATH=#{gopath}
    make
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

bash 'install_etcd' do
  code <<-EOH
    echo "DOWNLOADING ETCD BINARY"
    wget https://github.com/coreos/etcd/releases/download/v3.0.14/etcd-v3.0.14-linux-amd64.tar.gz
    tar xvf etcd-v3.0.14-linux-amd64.tar.gz
    echo "STARTING ETCD"
    nohup ./etcd-v3.0.14-linux-amd64/etcd > #{logs_dir}/etcd.log 2>&1 &
  EOH
  cwd "/home/#{user}"
  only_if (node['layerx']['deploy_marathon'] && LayerxHelper::in_path?('layerx-core') && LayerxHelper::in_path?('layerx-mesos-tpi'))
  user user
  group group
end

# Launch Layer-X
bash 'run_layerx' do
  code <<-EOH
    echo "STARTING ETCD"

    export PATH=#{ENV['PATH']}:#{gopath}/bin:/usr/local/go/bin:/opt/go/bin:#{layerx_path}/bin
    echo "STARTING LAYERX CORE"
    nohup layerx-core -etcd 127.0.0.1:2379 > #{logs_dir}/core.log 2>&1 &
    sleep 2
    echo "STARTING MESOS TPI"
    nohup layerx-mesos-tpi -layerx #{node['layerx']['bind_address']}:5000 -localip #{node['layerx']['bind_address']} > #{logs_dir}/mesos_tpi.log 2>&1 &
    echo "STARTING MESOS RPI"
    nohup layerx-mesos-rpi -layerx #{node['layerx']['bind_address']}:5000 -localip #{node['layerx']['bind_address']} --master #{node['layerx']['bind_address']}:5050 > #{logs_dir}/mesos_rpi.log 2>&1 &
  EOH
  only_if (LayerxHelper::in_path?('layerx-core') && LayerxHelper::in_path?('layerx-mesos-tpi'))
  user user
  group group
end

bash 'install & run marathon' do
  code <<-EOH
    sudo service marathon stop #in case it's running
    echo "DOWNLOADING MARATHON BINARY"
    curl -O http://downloads.mesosphere.com/marathon/v0.15.2/marathon-0.15.2.tgz && tar xzf marathon-0.15.2.tgz
    echo "STARTING MARATHON"
    nohup marathon-0.15.2/bin/start --master #{node['layerx']['bind_address']}:3000 --task_launch_confirm_timeout 1200000 --task_launch_timeout 1200000 > #{logs_dir}/marathon.log 2>&1 &
  EOH
  cwd "/home/#{user}"
  only_if (node['layerx']['deploy_marathon'] && LayerxHelper::in_path?('layerx-core') && LayerxHelper::in_path?('layerx-mesos-tpi'))
  user user
  group group
end
