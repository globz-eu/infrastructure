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
# Serverspec:: redis

require 'spec_helper'

set :backend, :exec

if os[:family] == 'ubuntu'
  # apt repository for redis should be there
  describe file('/etc/apt/sources.list.d/redis-server.list') do
    it { should_not exist }
  end

  # redis should not be installed
  describe package('redis-server') do
    it { should_not be_installed }
  end

  # redis should not be running
  describe service('redis-server') do
    it { should_not be_enabled }
    it { should_not be_running }
  end
end
