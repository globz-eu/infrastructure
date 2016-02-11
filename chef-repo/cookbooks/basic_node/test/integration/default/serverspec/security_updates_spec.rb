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

describe file('/etc/apt/apt.conf.d/50unattended-upgrades') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_mode 644 }
  it { should contain 'Unattended-Upgrade::Allowed-Origins {\n        "Ubuntu trusty-security";' }
  it { should contain '//      "Ubuntu trusty-updates";' }
  it { should contain 'Unattended-Upgrade::Mail "admin@example.com";' }
end

describe file('/etc/apt/apt.conf.d/10periodic') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_mode 644 }
  it { should contain 'APT::Periodic::Update-Package-Lists "1";' }
  it { should contain 'APT::Periodic::Download-Upgradeable-Packages "1";' }
  it { should contain 'APT::Periodic::AutocleanInterval "7";' }
  it { should contain 'APT::Periodic::Unattended-Upgrade "1";' }
end

describe package('apticron') do
  it { should be_installed}
end

describe file('/etc/apticron/apticron.conf') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_mode 644 }
  it { should contain 'EMAIL="admin@example.com"' }
end
