# Cookbook:: install_scripts
# Spec:: default

require 'spec_helper'

describe 'install_scripts::default' do
  ['14.04', '16.04'].each do |version|
    context "When all parameters are default, on an Ubuntu #{version} platform" do
      let(:chef_run) do
        runner = ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version)
        runner.converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'includes the expected recipes' do
        expect(chef_run).to include_recipe('apt::default')
        expect(chef_run).to include_recipe('install_scripts::user')
        expect(chef_run).to include_recipe('install_scripts::scripts')
      end
    end
  end
end
