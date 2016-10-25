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

gopath = ENV['GOPATH'] ||= "#{ENV['HOME']}/go"
repo_dir = "#{gopath}/src/github.com/emc-advanced-dev"
layerx_path = "#{repo_dir}/layerx"

directory "#{repo_dir}" do
  action :create
  mode 0755
  recursive true
end

#Clone LayerX from github
git layerx_path do
  repository 'git://github.com/emc-advanced-dev/layerx.git'
  reference 'master'
  action :sync
end

bash 'build_layerx' do
  # Validate go is installed
  unless LayerxHelper::in_path?('go')
    raise 'go executable not found in PATH'
  end
  # make & put binaries into path
  cwd layerx_path
  code <<-EOH
    make
    sudo cp #{layerx_path}/bin/* /usr/local/bin
  EOH
end
