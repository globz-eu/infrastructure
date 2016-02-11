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

describe file('/home/node_admin/.ssh') do
  it { should exist }
  it { should be_directory }
end

describe file('/home/node_admin/.ssh/authorized_keys') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'node_admin' }
  its(:content) { should match 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDV6LFiLYnDGQu/DFgMcuAD1BAqQp9cjKM5872hHS4d3tIeT5kcW7jUhEkJqo5OFtmPChdI4IchlzkuOzUHvNAuwgUkbhp0HSXDUiXCUDJLTkBsCg7iYIBEmqQF/xPHYvYoMmJxx4nS6SuXh9iYAHanGmEnVQtAChzbkEsARGhOG9CpUnqz7v+35qymNeEaj2Imw7ItQTh3WFZRzD+vaAh5+tmgE2JvjiGWt5NQa/5E91VOOj9hfzMzArGoCVDfTmdReyMYHKpVH3vb4uRfXU9/aewPj8ue1VJ25FbA3Z1vb9bjWAF4qwvJpXhWWY3rZeBD2cL4i5uLfDa2uBjb3JmdBR71oD/OiomJWfdC9zKjQTh8FGt32GQxFi35jUthBV2gIiyxAuFkBjyTnXoTXMUtjUoTl6KIwBuOoEvEA337IwyPT7yb4mFbK5giV4KwlXmX8Ju/sL9NYq8Dku95ZtLlz4wyaY2SF8RDPh8GsB/EVE/UYvlOSOZvYYKZkRCHWMGTVHUUmOWlq7UUPD8Pl3hUFaVAHzeRTumeXC3jhntVW1wRpIYDSXvdVzurfxpMrmvA+HQUxxHm17Kj5aq47Zoh2vZWsIUyPpsHv/mmvumZSoeCw+0b302XvSVYTy7j73amvewB4UJFI14ocnSH0jAE+axn7PYJr1WB6QB14FE2Bw== admin@adminPC'}
end

describe file('/etc/ssh/sshd_config') do
  it { should be_file }
end
