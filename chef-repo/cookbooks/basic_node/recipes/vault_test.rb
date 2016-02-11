include_recipe 'chef-vault'

vault_test_item = chef_vault_item('basic_node', 'vault_test')

file '/home/node_admin/test_file.txt' do
  content "password: #{vault_test_item['password']}"
end