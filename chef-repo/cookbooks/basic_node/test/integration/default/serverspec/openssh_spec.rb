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
# Cookbook Name:: basic_node
# Recipe:: openssh

require 'spec_helper'

set :backend, :exec

describe package('openssh-server') do
  it { should be_installed }
end

describe service('ssh') do
  it { should be_enabled }
  it { should be_running }
end

describe file('/home/node_admin/.ssh') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'node_admin' }
  it { should be_grouped_into 'node_admin' }
  it { should be_mode 750 }
end

describe file('/home/node_admin/.ssh/authorized_keys') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'node_admin' }
  it { should be_grouped_into 'node_admin' }
  it { should be_mode 640 }
  its(:md5sum) { should eq '99f40d69488f7264e8cf7cf8126fbb37' }
end

describe file('/etc/ssh/sshd_config') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 644 }
  its(:md5sum) { should eq 'b038bfea872686f44976f5f484d46923' }
end
