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

describe 'basic_node::remote_unlock' do
  context 'When all attributes are default, on an Ubuntu 14.04 platform' do
    include ChefVault::TestFixtures.rspec_shared_context(true)
    let(:chef_run) do
      runner = ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04')
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      expect{ chef_run }.to_not raise_error
    end

    it 'installs the dropbear package' do
      expect(chef_run).to install_package( 'dropbear' )
    end

    it 'creates the /etc/initramfs-tools/root/.ssh directory'do
      expect(chef_run).to create_directory('/etc/initramfs-tools/root/.ssh').with(
          owner: 'root',
          group: 'root',
          mode: '0750'
      )
    end

    it 'appends or creates the initramfs authorized_keys file' do
      expect(chef_run).to create_template('/etc/initramfs-tools/root/.ssh/authorized_keys').with(
          owner: 'root',
          group: 'root',
          mode: '0640',
          source: 'authorized_keys.erb',
          variables: {
              admin_key: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDV6LFiLYnDGQu/DFgMcuAD1BAqQp9cjKM5872hHS4d3tIeT5kcW7jUhEkJqo5OFtmPChdI4IchlzkuOzUHvNAuwgUkbhp0HSXDUiXCUDJLTkBsCg7iYIBEmqQF/xPHYvYoMmJxx4nS6SuXh9iYAHanGmEnVQtAChzbkEsARGhOG9CpUnqz7v+35qymNeEaj2Imw7ItQTh3WFZRzD+vaAh5+tmgE2JvjiGWt5NQa/5E91VOOj9hfzMzArGoCVDfTmdReyMYHKpVH3vb4uRfXU9/aewPj8ue1VJ25FbA3Z1vb9bjWAF4qwvJpXhWWY3rZeBD2cL4i5uLfDa2uBjb3JmdBR71oD/OiomJWfdC9zKjQTh8FGt32GQxFi35jUthBV2gIiyxAuFkBjyTnXoTXMUtjUoTl6KIwBuOoEvEA337IwyPT7yb4mFbK5giV4KwlXmX8Ju/sL9NYq8Dku95ZtLlz4wyaY2SF8RDPh8GsB/EVE/UYvlOSOZvYYKZkRCHWMGTVHUUmOWlq7UUPD8Pl3hUFaVAHzeRTumeXC3jhntVW1wRpIYDSXvdVzurfxpMrmvA+HQUxxHm17Kj5aq47Zoh2vZWsIUyPpsHv/mmvumZSoeCw+0b302XvSVYTy7j73amvewB4UJFI14ocnSH0jAE+axn7PYJr1WB6QB14FE2Bw== admin@adminPC',
          })
      expect(chef_run).to render_file('/etc/initramfs-tools/root/.ssh/authorized_keys').with_content(
          %r(ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDV6LFiLYnDGQu/DFgMcuAD1BAqQp9cjKM5872hHS4d3tIeT5kcW7jUhEkJqo5OFtmPChdI4IchlzkuOzUHvNAuwgUkbhp0HSXDUiXCUDJLTkBsCg7iYIBEmqQF/xPHYvYoMmJxx4nS6SuXh9iYAHanGmEnVQtAChzbkEsARGhOG9CpUnqz7v\+35qymNeEaj2Imw7ItQTh3WFZRzD\+vaAh5\+tmgE2JvjiGWt5NQa/5E91VOOj9hfzMzArGoCVDfTmdReyMYHKpVH3vb4uRfXU9/aewPj8ue1VJ25FbA3Z1vb9bjWAF4qwvJpXhWWY3rZeBD2cL4i5uLfDa2uBjb3JmdBR71oD/OiomJWfdC9zKjQTh8FGt32GQxFi35jUthBV2gIiyxAuFkBjyTnXoTXMUtjUoTl6KIwBuOoEvEA337IwyPT7yb4mFbK5giV4KwlXmX8Ju/sL9NYq8Dku95ZtLlz4wyaY2SF8RDPh8GsB/EVE/UYvlOSOZvYYKZkRCHWMGTVHUUmOWlq7UUPD8Pl3hUFaVAHzeRTumeXC3jhntVW1wRpIYDSXvdVzurfxpMrmvA\+HQUxxHm17Kj5aq47Zoh2vZWsIUyPpsHv/mmvumZSoeCw\+0b302XvSVYTy7j73amvewB4UJFI14ocnSH0jAE\+axn7PYJr1WB6QB14FE2Bw== admin@adminPC)
      )
    end

    it 'creates the crypt_unlock.sh file' do
      expect(chef_run).to create_template('/etc/initramfs-tools/hooks/crypt_unlock.sh').with(
          owner: 'root',
          group: 'root',
          mode: '0750',
          source: 'crypt_unlock.sh.erb',
      )
    end

    it 'manages the dropbear file' do
      expect(chef_run).to create_template('/usr/share/initramfs-tools/scripts/init-bottom/dropbear').with(
          owner: 'root',
          group: 'root',
          mode: '0640',
          source: 'dropbear.erb',
          variables: {
              interface: 'eth1',
          })
      expect(chef_run).to render_file('/usr/share/initramfs-tools/scripts/init-bottom/dropbear').with_content(
          /^ifconfig eth1 0\.0\.0\.0 down/
      )
    end

    it 'manages the initramfs.conf file' do
      initramfs_conf = [
            /^DROPBEAR=y/,
            /^DEVICE=eth1/,
            /^IP=10\.10\.10\.10:::255\.255\.255\.0::eth1:off/
      ]
      expect(chef_run).to create_template('/etc/initramfs-tools/initramfs.conf').with(
          owner: 'root',
          group: 'root',
          mode: '0640',
          source: 'initramfs.conf.erb',
          variables: {
              interface: 'eth1',
              ip: '10.10.10.10',
              netmask: '255.255.255.0',
              dropbear: 'DROPBEAR=y'
          })
      initramfs_conf.each do |i|
        expect(chef_run).to render_file('/etc/initramfs-tools/initramfs.conf').with_content(i)
      end
    end

    it 'runs the "update-initramfs" command' do
      expect(chef_run).to_not run_execute('update-initramfs -u')
      resource = chef_run.execute('update-initramfs -u')
      expect(resource).to subscribe_to('template[/etc/initramfs-tools/initramfs.conf]').on(:run).immediately
    end

    it 'runs the "update-rc.d -f dropbear remove" command' do
      expect(chef_run).to_not run_execute('update-rc.d -f dropbear remove')
      resource = chef_run.execute('update-rc.d -f dropbear remove')
      expect(resource).to subscribe_to('execute[update-initramfs -u]').on(:run).immediately
    end

  end
end

