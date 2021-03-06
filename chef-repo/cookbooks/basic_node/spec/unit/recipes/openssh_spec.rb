# Cookbook Name:: basic_node
# Recipe:: openssh

require 'spec_helper'

describe 'basic_node::openssh' do
  ['14.04', '16.04'].each do |version|
    context "When all attributes are default, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        runner = ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version)
        runner.converge(described_recipe)
      end

      it 'converges successfully' do
        expect{ chef_run }.to_not raise_error
      end

      it 'installs the openssh-server package' do
        expect(chef_run).to install_package( 'openssh-server' )
      end

      it 'starts the ssh service' do
        expect(chef_run).to start_service( 'ssh' )
      end

      it 'enables the ssh service' do
        expect(chef_run).to enable_service( 'ssh' )
      end

      it 'creates the admin user .ssh directory' do
        expect(chef_run).to create_directory('/home/node_admin/.ssh').with(
            owner: 'node_admin',
            group: 'node_admin',
            mode: '0750',
        )
      end

      it 'appends or creates the authorized_keys file' do
        expect(chef_run).to create_template('/home/node_admin/.ssh/authorized_keys').with(
           owner: 'node_admin',
           group: 'node_admin',
           mode: '0640',
           source: 'authorized_keys.erb',
           variables: {
               admin_key: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDV6LFiLYnDGQu/DFgMcuAD1BAqQp9cjKM5872hHS4d3tIeT5kcW7jUhEkJqo5OFtmPChdI4IchlzkuOzUHvNAuwgUkbhp0HSXDUiXCUDJLTkBsCg7iYIBEmqQF/xPHYvYoMmJxx4nS6SuXh9iYAHanGmEnVQtAChzbkEsARGhOG9CpUnqz7v+35qymNeEaj2Imw7ItQTh3WFZRzD+vaAh5+tmgE2JvjiGWt5NQa/5E91VOOj9hfzMzArGoCVDfTmdReyMYHKpVH3vb4uRfXU9/aewPj8ue1VJ25FbA3Z1vb9bjWAF4qwvJpXhWWY3rZeBD2cL4i5uLfDa2uBjb3JmdBR71oD/OiomJWfdC9zKjQTh8FGt32GQxFi35jUthBV2gIiyxAuFkBjyTnXoTXMUtjUoTl6KIwBuOoEvEA337IwyPT7yb4mFbK5giV4KwlXmX8Ju/sL9NYq8Dku95ZtLlz4wyaY2SF8RDPh8GsB/EVE/UYvlOSOZvYYKZkRCHWMGTVHUUmOWlq7UUPD8Pl3hUFaVAHzeRTumeXC3jhntVW1wRpIYDSXvdVzurfxpMrmvA+HQUxxHm17Kj5aq47Zoh2vZWsIUyPpsHv/mmvumZSoeCw+0b302XvSVYTy7j73amvewB4UJFI14ocnSH0jAE+axn7PYJr1WB6QB14FE2Bw== admin@adminPC',
           })
        expect(chef_run).to render_file('/home/node_admin/.ssh/authorized_keys').with_content(
              %r(ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDV6LFiLYnDGQu/DFgMcuAD1BAqQp9cjKM5872hHS4d3tIeT5kcW7jUhEkJqo5OFtmPChdI4IchlzkuOzUHvNAuwgUkbhp0HSXDUiXCUDJLTkBsCg7iYIBEmqQF/xPHYvYoMmJxx4nS6SuXh9iYAHanGmEnVQtAChzbkEsARGhOG9CpUnqz7v\+35qymNeEaj2Imw7ItQTh3WFZRzD\+vaAh5\+tmgE2JvjiGWt5NQa/5E91VOOj9hfzMzArGoCVDfTmdReyMYHKpVH3vb4uRfXU9/aewPj8ue1VJ25FbA3Z1vb9bjWAF4qwvJpXhWWY3rZeBD2cL4i5uLfDa2uBjb3JmdBR71oD/OiomJWfdC9zKjQTh8FGt32GQxFi35jUthBV2gIiyxAuFkBjyTnXoTXMUtjUoTl6KIwBuOoEvEA337IwyPT7yb4mFbK5giV4KwlXmX8Ju/sL9NYq8Dku95ZtLlz4wyaY2SF8RDPh8GsB/EVE/UYvlOSOZvYYKZkRCHWMGTVHUUmOWlq7UUPD8Pl3hUFaVAHzeRTumeXC3jhntVW1wRpIYDSXvdVzurfxpMrmvA\+HQUxxHm17Kj5aq47Zoh2vZWsIUyPpsHv/mmvumZSoeCw\+0b302XvSVYTy7j73amvewB4UJFI14ocnSH0jAE\+axn7PYJr1WB6QB14FE2Bw== admin@adminPC)
        )
      end

      it 'creates the sshd_config file' do
        sshd_config = [
            /^PermitRootLogin no/,
            /^PasswordAuthentication no/,
            /^PubkeyAuthentication yes/,
            /^RSAAuthentication yes/,
            /^AllowUsers node_admin vagrant/
        ]
        expect(chef_run).to create_template('/etc/ssh/sshd_config').with(
          owner: 'root',
          group: 'root',
          mode: '0644',
          source: 'sshd_config.erb',
          variables: {
              permit_root_login: chef_run.node['openssh']['sshd']['permit_root_login'],
              password_authentication: chef_run.node['openssh']['sshd']['password_authentication'],
              pubkey_authentication: chef_run.node['openssh']['sshd']['pubkey_authentication'],
              rsa_authentication: chef_run.node['openssh']['sshd']['rsa_authentication'],
              allowed_users: 'node_admin vagrant'
          }
        )
        sshd_config.each do |s|
          expect(chef_run).to render_file('/etc/ssh/sshd_config').with_content(s)
        end
      end

      it 'notifies ssh service on creation of sshd_config' do
        resource = chef_run.template('/etc/ssh/sshd_config')
        expect(resource).to notify('service[ssh]').to(:restart).immediately
      end
    end
  end
end