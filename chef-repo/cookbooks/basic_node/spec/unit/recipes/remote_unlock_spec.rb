# Cookbook Name:: basic_node
# Recipe:: remote_unlock

require 'spec_helper'

describe 'basic_node::remote_unlock' do
  ['14.04', '16.04'].each do |version|
    context "When all attributes are default, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          if version == '14.04'
            node.set['basic_node']['node_number'] = '000'
          elsif version == '16.04'
            node.set['basic_node']['node_number'] = '001'
          end
          node.set['basic_node']['remote_unlock']['encryption'] = true
        end.converge(described_recipe)
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
        if version == '14.04'
          initramfs_conf = [
                /^DROPBEAR=y/,
                /^DEVICE=eth1/,
                /^IP=10\.10\.1\.10:::255\.255\.255\.0::eth1:off/
          ]
          ip = '10.10.1.10'
        elsif version == '16.04'
          initramfs_conf = [
              /^DROPBEAR=y/,
              /^DEVICE=eth1/,
              /^IP=10\.10\.1\.11:::255\.255\.255\.0::eth1:off/
          ]
          ip = '10.10.1.11'
        end

        expect(chef_run).to create_template('/etc/initramfs-tools/initramfs.conf').with(
            owner: 'root',
            group: 'root',
            mode: '0640',
            source: 'initramfs.conf.erb',
            variables: {
                interface: 'eth1',
                ip: ip,
                netmask: '255.255.255.0',
                dropbear: 'DROPBEAR=y'
            })
        initramfs_conf.each do |i|
          expect(chef_run).to render_file('/etc/initramfs-tools/initramfs.conf').with_content(i)
        end
        resource = chef_run.template('/etc/initramfs-tools/initramfs.conf')
        expect(resource).to notify('execute[update-initramfs -u]').to(:run).immediately
      end

      it 'runs the "update-initramfs" command' do
        expect(chef_run).to_not run_execute('update-initramfs -u')
        resource = chef_run.execute('update-initramfs -u')
        expect(resource).to notify('execute[update-rc.d -f dropbear remove]').to(:run).immediately
      end

      it 'runs the "update-rc.d -f dropbear remove" command' do
        expect(chef_run).to_not run_execute('update-rc.d -f dropbear remove')
      end
    end
  end
end

