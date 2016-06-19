include_recipe 'resolver::default'
include_recipe 'latest-git::default'

node.default['latest-nodejs']['install'] = 'current'
include_recipe 'latest-nodejs::default'

include_recipe 'modern_nginx::default'
include_recipe 'modern_nginx::cert'

id = 'volgactf-ru'

if node.chef_environment.start_with? 'development'
  node.default[id]['main']['repository'] = 'git@github.com:VolgaCTF/volgactf.ru-jekyll.git'
  node.default[id]['arch_2015']['repository'] = 'git@github.com:VolgaCTF/2015.volgactf.ru.git'

  ssh_known_hosts_entry 'github.com'

  data_bag_item(id, node.chef_environment).to_hash.fetch('ssh', {}).each do |key_type, key_contents|
    ssh_user_private_key key_type do
      key key_contents
      user node[id]['user']
    end
  end
end

include_recipe 'volgactf-ru::main'
include_recipe 'volgactf-ru::arch_2015'
