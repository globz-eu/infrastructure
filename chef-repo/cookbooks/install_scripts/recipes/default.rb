# Cookbook Name:: install_scripts
# Recipe:: default

include_recipe 'apt::default'
include_recipe 'install_scripts::user'
include_recipe 'install_scripts::scripts'
