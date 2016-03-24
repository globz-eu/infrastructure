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

require 'spec_helper'

set :backend, :exec

describe package('unattended-upgrades') do
  it { should be_installed }
end

describe package('bsd-mailx') do
  it { should_not be_installed }
end

describe file('/etc/apt/apt.conf.d/50unattended-upgrades') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 644 }
  its(:md5sum) { should eq 'a89c22db4df9a6331162e78f561dd8ea' }
  it { should contain 'Unattended-Upgrade::Mail "admin@example.com";' }
end

describe file('/etc/apt/apt.conf.d/20auto-upgrades') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_mode 644 }
  its(:md5sum) { should eq '1c261d6541420797f8b824d65ac5c197' }
end
