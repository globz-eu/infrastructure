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
# Recipe:: remote_unlock

require 'spec_helper'
require 'date'

set :backend, :exec

describe package('dropbear') do
  it { should be_installed }
end

describe file('/etc/initramfs-tools/root/.ssh') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 750 }
end

describe file('/etc/initramfs-tools/root/.ssh/authorized_keys') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 640 }
  its(:content) { should match(%r(ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDV6LFiLYnDGQu/DFgMcuAD1BAqQp9cjKM5872hHS4d3tIeT5kcW7jUhEkJqo5OFtmPChdI4IchlzkuOzUHvNAuwgUkbhp0HSXDUiXCUDJLTkBsCg7iYIBEmqQF/xPHYvYoMmJxx4nS6SuXh9iYAHanGmEnVQtAChzbkEsARGhOG9CpUnqz7v\+35qymNeEaj2Imw7ItQTh3WFZRzD\+vaAh5\+tmgE2JvjiGWt5NQa/5E91VOOj9hfzMzArGoCVDfTmdReyMYHKpVH3vb4uRfXU9/aewPj8ue1VJ25FbA3Z1vb9bjWAF4qwvJpXhWWY3rZeBD2cL4i5uLfDa2uBjb3JmdBR71oD/OiomJWfdC9zKjQTh8FGt32GQxFi35jUthBV2gIiyxAuFkBjyTnXoTXMUtjUoTl6KIwBuOoEvEA337IwyPT7yb4mFbK5giV4KwlXmX8Ju/sL9NYq8Dku95ZtLlz4wyaY2SF8RDPh8GsB/EVE/UYvlOSOZvYYKZkRCHWMGTVHUUmOWlq7UUPD8Pl3hUFaVAHzeRTumeXC3jhntVW1wRpIYDSXvdVzurfxpMrmvA\+HQUxxHm17Kj5aq47Zoh2vZWsIUyPpsHv/mmvumZSoeCw\+0b302XvSVYTy7j73amvewB4UJFI14ocnSH0jAE\+axn7PYJr1WB6QB14FE2Bw== admin@adminPC)) }
  its(:md5sum) { should eq '77322ef05ceebe1647ba639bf15924cf' }
end

describe file('/etc/initramfs-tools/hooks/crypt_unlock.sh') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 750 }
  its(:md5sum) { should eq 'e10a28b4ec42720debc878897b8d07a8' }
end

describe file('/etc/initramfs-tools/initramfs.conf') do
  initramfs_conf = [
      /^DROPBEAR=y/,
      /^DEVICE=eth1/,
      /^IP=10\.10\.10\.10:::255\.255\.255\.0::eth1:off/
  ]
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 640 }
  initramfs_conf.each do |i|
    its(:content) { should match(i) }
  end
  its(:md5sum) { should eq 'c488564c6cce94fd9067f7822617cc11' }
end

describe file('/usr/share/initramfs-tools/scripts/init-bottom/dropbear') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 640 }
  its(:content) { should match(/ifconfig eth1 0.0.0.0 down/)}
  its(:md5sum) { should eq 'b79d37bb91e541683935b2ce238f3240' }
end

describe command ( 'ls -l /boot | grep initrd.img' ) do
  day = DateTime.now.strftime("%d")
  if day.to_i < 10
    day = day[1]
  end
  month = Date::ABBR_MONTHNAMES[Date.today.month]
  its(:stdout) { should match(/#{month}\s+#{day}/)}
end

if os[:release] == '14.04'
  describe command( 'update-initramfs -u' ) do
    its(:stdout) { should match(/update-initramfs: Generating \/boot\/initrd\.img-3\.\d{2}\.0-\d{2}-generic/) }
    its(:stdout) { should_not match(/error/) }
  end
elsif os[:release] == '16.04'
  describe command( 'update-initramfs -u' ) do
    its(:stdout) { should match(/update-initramfs: Generating \/boot\/initrd\.img-4\.\d+\.0-\d{2}-generic/) }
    its(:stdout) { should_not match(/error/) }
  end
end

if os[:release] == '14.04'
  describe command( 'update-rc.d -n -f dropbear remove') do
    its(:stdout) { should match(/Removing any system startup links for \/etc\/init.d\/dropbear/) }
    its(:stdout) { should_not match(/\/etc\/rc\d\.d\/[KS]20dropbear/) }
  end
elsif os[:release] == '16.04'
  describe command( 'update-rc.d -n -f dropbear remove') do
    its(:stderr) { should match(/insserv: dryrun, not creating \.depend\.boot, \.depend\.start, and \.depend\.stop/) }
    its(:stdout) { should_not match(/\/etc\/rc\d\.d\/[KS]20dropbear/) }
  end
end
