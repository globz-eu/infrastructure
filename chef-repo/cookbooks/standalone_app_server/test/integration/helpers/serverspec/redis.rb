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
# Cookbook Name:: db_server
# Server Spec:: redis

require 'spec_helper'

set :backend, :exec

if os[:family] == 'ubuntu'
  # apt repository for redis should be there
  describe file('/etc/apt/sources.list.d/redis-server.list') do
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_mode 644 }
    if os[:release] == '16.04'
      its(:content) { should match %r{deb\s+"http://ppa\.launchpad\.net/chris-lea/redis-server/ubuntu" xenial main} }
      its(:content) { should match %r{deb-src\s+"http://ppa\.launchpad\.net/chris-lea/redis-server/ubuntu" xenial main} }
      its(:md5sum) { should eq 'cac8b8e7ee6014ef5cdc030f345094be' }
    elsif os[:release] == '14.04'
      its(:content) { should match %r{deb\s+"http://ppa\.launchpad\.net/chris-lea/redis-server/ubuntu" trusty main} }
      its(:content) { should match %r{deb-src\s+"http://ppa\.launchpad\.net/chris-lea/redis-server/ubuntu" trusty main} }
      its(:md5sum) { should eq '2089a35d168e1f90e569c4d9fb88e98f' }
    end
  end

  # redis should be installed
  describe package('redis-server') do
    it { should be_installed }
  end

  # redis should be running
  describe service('redis-server') do
    it { should be_enabled }
    it { should be_running }
  end
end
