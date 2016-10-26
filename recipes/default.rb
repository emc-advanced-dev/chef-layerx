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

directory "#{repo_dir}" do
  action :create
  mode 0755
  recursive true
  owner node['layerx']['user']
  group node['layerx']['group']
end

#Clone LayerX from github
git layerx_path do
  repository 'git://github.com/emc-advanced-dev/layerx.git'
  reference 'master'
  action :sync
  user node['layerx']['user']
  group node['layerx']['group']
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
  only_if LayerxHelper::in_path?('go')
  only_if LayerxHelper::in_path?('go-bindata')
  only_if LayerxHelper::in_path?('go-bindata-assetfs')
  user node['layerx']['user']
  group node['layerx']['group']
end

logs_dir = "/var/log/layerx"

directory "#{logs_dir}" do
  action :create
  mode 0755
  recursive true
  owner node['layerx']['user']
  group node['layerx']['group']
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
  EOH
  only_if LayerxHelper::in_path?('layerx-core')
  user node['layerx']['user']
  group node['layerx']['group']
end
