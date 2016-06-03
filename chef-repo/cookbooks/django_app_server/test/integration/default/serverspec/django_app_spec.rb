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
# Cookbook Name:: django_app_server
# Server Spec:: django_app

require 'spec_helper'
require 'find'

set :backend, :exec

if os[:family] == 'ubuntu'
  describe package('git') do
    it { should be_installed }
  end

  # File structure for app should be present
  describe file('/home/app_user/sites') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'app_user' }
    it { should be_grouped_into 'www-data' }
    it { should be_mode 550 }
  end

  # Virtual environment directory structure should be present
  describe file('/home/app_user/.envs') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'app_user' }
    it { should be_grouped_into 'app_user' }
    it { should be_mode 500 }
  end
end