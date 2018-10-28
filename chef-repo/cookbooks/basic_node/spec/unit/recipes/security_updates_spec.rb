require 'spec_helper'

describe 'basic_node::security_updates' do
  ['14.04', '16.04'].each do |version|
    context "When all attributes are default, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        runner = ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version)
        runner.converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'installs the apticron package' do
        expect(chef_run).to install_package('apticron')
      end

      it 'manages the apticron.conf file' do
        expect(chef_run).to create_template('/etc/apticron/apticron.conf').with(
          owner: 'root',
          group: 'root',
          mode: '0644',
          variables: { admin_email: 'admin@example.com' }
        )
        expect(chef_run).to render_file('/etc/apticron/apticron.conf').with_content(/^EMAIL="admin@example\.com"/)
      end
    end
  end
end
