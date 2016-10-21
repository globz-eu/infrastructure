# =====================================================================
# Web app infrastructure for Django project
# Copyright (C) 2016 Stefan Dieterle
# e-mail: golgoths@yahoo.fr
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# =====================================================================
#
# Cookbook Name:: chef_server
# Recipe:: install_chef_server

require 'spec_helper'

set :backend, :exec

describe file('/home/chef_user/scripts/install_script') do
  it {should exist}
  it {should be_file}
  it {should be_owned_by 'chef_user'}
  it {should be_grouped_into 'chef_user'}
  it {should be_mode 640}
end

describe package('chef-server') do
  it {should be_installed}
end
