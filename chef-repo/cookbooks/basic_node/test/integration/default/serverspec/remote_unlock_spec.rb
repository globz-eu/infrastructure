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

describe file('/etc/initramfs-tools/.ssh') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 750 }
end

describe file('/etc/initramfs-tools/.ssh/authorized_keys') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 640 }
  its(:md5sum) { should eq '99f40d69488f7264e8cf7cf8126fbb37' }
end

describe file('/etc/initramfs-tools/hooks/crypt_unlock.sh') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 750 }
  its(:md5sum) { should eq '45293c973630d2cde69dbfe296d0dad0' }
end

describe file('/etc/initramfs-tools/initramfs.conf') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 640 }
  its(:content) { should match(/DROPBEAR=y/)}
  its(:content) { should match(/DEVICE=eth1/)}
  its(:content) { should match(/IP=10.10.10.10:::255.255.255.0::eth1:off/)}
  its(:md5sum) { should eq '2526d52598ee3ee9000416db9f9f56f7' }
end

describe file('/usr/share/initramfs-tools/scripts/init-bottom/dropbear') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 640 }
  its(:content) { should match(/ifconfig eth1 0.0.0.0 down/)}
  its(:md5sum) { should eq 'cc3205a968593a41088577c64cb3bc06' }
end

describe command ( 'ls -l /boot | grep initrd.img-3.19.0-56-generic' ) do
  day = DateTime.now.strftime("%d")
  month = Date::ABBR_MONTHNAMES[Date.today.month]
  time_regex = "/#{month} #{day}/"
  its(:stdout) { should match(time_regex)}
end

describe command( 'update-initramfs -u' ) do
  its(:stdout) { should match(/update-initramfs: Generating \/boot\/initrd\.img-3\.\d{2}\.0-\d{2}-generic/) }
  its(:stdout) { should_not match(/error/) }
end

describe command( 'update-rc.d -n -f dropbear remove') do
  its(:stdout) { should match(/Removing any system startup links for \/etc\/init.d\/dropbear/) }
  its(:stdout) { should_not match(/\/etc\/rc\d\.d\/[KS]20dropbear/) }
end
