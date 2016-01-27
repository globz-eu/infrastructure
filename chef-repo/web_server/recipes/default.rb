#
# Cookbook Name:: web_server
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

include_recipe 'apt::default'

package 'nginx'

service 'nginx' do
  action [:enable, :start]
end
