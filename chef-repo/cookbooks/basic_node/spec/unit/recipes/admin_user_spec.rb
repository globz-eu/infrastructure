require 'spec_helper'

describe 'basic_node::admin_user' do
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

      it 'creates the admin user' do
        expect(chef_run).to create_user('node_admin').with(
                                                    home: '/home/node_admin',
                                                    shell: '/bin/bash',
                                                    password: '$6$oWrcKQHI2UL$rrFuhMmBnMpw102eOdNzBWibU7BnQyaT3031KiPpz8VqOqzLbIBiC.wpY8Uw4Z3n3LsgtfxpqaN5b9LuVGCfX.'
        )
      end

      it 'adds admin to group sudo' do
        expect(chef_run).to manage_group('sudo').with(
                                                    append: true,
                                                    members: ['node_admin']
        )
      end

      it 'adds admin to group adm' do
        expect(chef_run).to manage_group('adm').with(
            append: true,
            members: ['node_admin']
        )
      end

    end
  end
end