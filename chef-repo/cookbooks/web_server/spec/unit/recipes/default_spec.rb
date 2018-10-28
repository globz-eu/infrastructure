# Cookbook Name:: web_server
# Spec:: default


require 'spec_helper'

describe 'web_server::default' do
  ['14.04', '16.04'].each do |version|
    context "When all attributes are default, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          if version == '14.04'
            node.set['web_server']['node_number'] = '000'
          elsif version == '16.04'
            node.set['web_server']['node_number'] = '001'
          end
        end.converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'includes apt and nginx recipes' do
        recipes = %w(apt::default chef-vault install_scripts::user web_server::nginx)
        recipes.each do |r|
          expect(chef_run).to include_recipe(r)
        end
      end
    end
  end
end

describe 'web_server::default' do
  ['14.04', '16.04'].each do |version|
    context "When app repo is specified, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['web_server']['git']['app_repo'] = 'https://github.com/globz-eu/django_base.git'
          if version == '14.04'
            node.set['web_server']['node_number'] = '000'
          elsif version == '16.04'
            node.set['web_server']['node_number'] = '001'
          end
        end.converge(described_recipe)
      end

      before do
        stub_command('ls /home/web_user/sites/django_base/down/index.html').and_return(true)
        stub_command('pip list | grep virtualenv').and_return(false)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'includes apt and nginx recipes' do
        recipes = %w(apt::default chef-vault install_scripts::user install_scripts::scripts web_server::nginx)
        recipes.each do |r|
          expect(chef_run).to include_recipe(r)
        end
      end
    end
  end
end
