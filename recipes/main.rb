id = 'volgactf-ru'

fqdn = node[id][:main][:fqdn]
base_dir = ::File.join '/var/www', fqdn

directory base_dir do
  owner node[id][:user]
  group node[id][:group]
  mode 0755
  recursive true
  action :create
end

git2 base_dir do
  url node[id][:main][:repository]
  branch node[id][:main][:revision]
  user node[id][:user]
  group node[id][:group]
  action :create
end

if node.chef_environment.start_with? 'development'
  data_bag_item(id, node.chef_environment).to_hash.fetch('git_config', {}).each do |key, value|
    git_config key do
      value value
      scope 'local'
      path base_dir
      user node[id][:user]
      action :set
    end
  end
end

logs_dir = ::File.join base_dir, 'logs'

directory logs_dir do
  owner node[id][:user]
  group node[id][:group]
  mode 0755
  recursive true
  action :create
end

nodejs_npm '.' do
  path base_dir
  json true
  user node[id][:user]
  group node[id][:group]
end

execute 'Install Bower packages' do
  command 'npm run bower -- install'
  cwd base_dir
  user node[id][:user]
  group node[id][:group]
  environment 'HOME' => "/home/#{node[id][:user]}"
end

execute 'Build assets' do
  command 'npm run gulp'
  cwd base_dir
  user node[id][:user]
  group node[id][:group]
  environment(
    'HOME' => "/home/#{node[id][:user]}",
    'NODE_ENV' => node.chef_environment
  )
end

nginx_conf = ::File.join node[:nginx][:dir], 'sites-available', "#{fqdn}.conf"

template nginx_conf do
  Chef::Resource::Template.send(:include, ::ModernNginx::Helper)
  source 'main.conf.erb'
  mode 0644
  notifies :reload, 'service[nginx]', :delayed
  variables(
    fqdn: fqdn,
    acme_challenge: node.chef_environment.start_with?('production'),
    acme_challenge_directories: {
      "#{fqdn}" => get_acme_challenge_directory(fqdn),
      "www.#{fqdn}" => get_acme_challenge_directory("www.#{fqdn}")
    },
    ssl_certificate: get_ssl_certificate_path(fqdn),
    ssl_certificate_key: get_ssl_certificate_private_key_path(fqdn),
    hsts_max_age: node[id][:hsts_max_age],
    access_log: ::File.join(logs_dir, 'nginx_access.log'),
    error_log: ::File.join(logs_dir, 'nginx_error.log'),
    doc_root: ::File.join(base_dir, 'dist'),
    oscp_stapling: node.chef_environment.start_with?('production'),
    scts: node.chef_environment.start_with?('production'),
    scts_dir: get_scts_directory(fqdn),
    hpkp: node.chef_environment.start_with?('production'),
    hpkp_pins: get_hpkp_pins(fqdn),
    hpkp_max_age: node[id][:hpkp_max_age]
  )
  action :create
end

nginx_site "#{fqdn}.conf"
