# Cookbook Name:: basic_node
# Spec:: ntp

require 'spec_helper'

describe 'basic_node::ntp' do
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

      it 'installs the ntp package' do
        expect( chef_run ).to install_package('ntp')
      end

      it 'starts the ntp service' do
        expect(chef_run).to start_service( 'ntp' )
      end

      it 'enables the ntp service' do
        expect(chef_run).to enable_service( 'ntp' )
      end
    end
  end
end