# Cookbook:: install_scripts
# Spec:: user

require 'spec_helper'

describe 'install_scripts::user' do
  ['14.04', '16.04'].each do |version|
    context "When all attributes are default, on an Ubuntu #{version} platform" do
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version).converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'does not create a user' do
        expect(chef_run).to_not create_user('user')
      end
    end
  end
end

describe 'install_scripts::user' do
  ['14.04', '16.04'].each do |version|
    context "When user name, password and group are specified, on an Ubuntu #{version} platform" do
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['install_scripts']['users'] = [{
            :user => 'user',
            :password => '$6$YPpcwnaZtxEObrRR$RpqD1RgLVHOrr0BbAmVocf.6/yIU5.mW.hr.sm./xvwheoa9xBO6td71PUczQKfcaAcE1U2c3o0mOMb8ufvr5/',
            :groups => ['www-data'],
                                                  }]
        end.converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'creates the user' do
        expect(chef_run).to create_user('user').with(
            home: '/home/user',
            shell: '/bin/bash',
            password: '$6$YPpcwnaZtxEObrRR$RpqD1RgLVHOrr0BbAmVocf.6/yIU5.mW.hr.sm./xvwheoa9xBO6td71PUczQKfcaAcE1U2c3o0mOMb8ufvr5/'
        )
      end

      it 'adds user to group www-data' do
        expect(chef_run).to create_group('www-data').with(
            append: true,
            members: ['user']
        )
      end
    end
  end
end
