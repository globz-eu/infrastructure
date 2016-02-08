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


require 'serverspec'

set :backend, :exec

describe package('openssh-server') do
  it { should be_installed }
end

describe service('ssh') do
  it { should be_enabled }
  it { should be_running }
end

describe file('/home/admin/.ssh/authorized_keys') do
  it { should be_file }
end

describe file('/home/.ssh/authorized_keys') do
  it 'is pending'
end

describe file('/etc/ssh/sshd_config') do
  it { should be_file }
end

describe file('/etc/ssh/sshd_config') do
  it 'is pending'
end
