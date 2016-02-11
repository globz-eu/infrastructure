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

describe package('openssh-server') do
  it { should be_installed }
end

describe service('ssh') do
  it { should be_enabled }
  it { should be_running }
end

describe file("/home/#{$node['basic_node']['admin_user']['node_admin']}/.ssh") do
  it { should exist }
  it { should be_directory }
end

describe file('/home/' + $node['basic_node']['admin_user']['node_admin'] + '/.ssh/authorized_keys') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by $node['basic_node']['admin_user']['node_admin'] }
  it { should contain 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApPVju50vJyXJ0jYxn0PqauzbVLUqyV9aS/ezFjwD4AIQGBmYL9sl4FZxZMA2mNyWtJWeauLF+SyoUhg95JYBEfLYFJOH3mufl2V/SCwavkDqGnbepyrTRHXRkG6etNaaKEbbDoWdqxHo1eQVhjX8sR4slnIjQffgm8/pxOw3R30ilB1NfT73wtrVBGE/ryPloRRp1A16uBxO+5Fnac28LlHwHZXKXrbV8GeiWNTyE/RC+32NXHbOtZkBGc3jKVShCZ4+iKuU1wUGhMjdwUa4Jwmp0VKh8OlH6HkoErg2JLIrbSloz4Z769UkG8fPCb0DG04C0a79yU3w81n1GaqkjQIDAQAB'}
end

describe file('/etc/ssh/sshd_config') do
  it { should be_file }
end
