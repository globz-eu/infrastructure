# Cookbook Name:: db_server
# Spec:: redis

require 'spec_helper'

describe 'db_server::redis' do
  ['14.04', '16.04'].each do |version|
    context "When all attributes are default, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version).converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'includes the expected recipes' do
        expect(chef_run).to include_recipe('chef-vault')
      end

      it 'adds the repository for redis' do
        expect(chef_run).to_not add_apt_repository('redis-server').with({
                                                                        repo_name: 'ppa:chris-lea/redis-server'
                                                                    })
      end

      it 'installs the redis-server package' do
        expect(chef_run).to_not install_package('redis-server')
      end
    end
  end
end

describe 'db_server::redis' do
  ['14.04', '16.04'].each do |version|
    context "When all install redis is true, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['db_server']['redis']['install'] = true
        end.converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'includes the expected recipes' do
        expect(chef_run).to include_recipe('chef-vault')
        expect(chef_run).to include_recipe('apt')
      end

      it 'adds the repository for redis' do
        expect(chef_run).to add_apt_repository('redis-server').with({
            repo_name: 'redis-server',
            uri: 'ppa:chris-lea/redis-server',
            deb_src: true
                                                                    })
      end

      it 'installs the redis-server package' do
        expect(chef_run).to install_package('redis-server')
      end
    end
  end
end