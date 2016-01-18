include_recipe 'latest-git::default'
include_recipe 'latest-nodejs::default'
include_recipe 'modern_nginx::default'
include_recipe 'modern_nginx::cert'

id = 'volgactf-ru'

base_dir = ::File.join '/var/www', node[id][:fqdn]

directory base_dir do
  owner node[id][:user]
  group node[id][:group]
  mode 0755
  recursive true
  action :create
end

git base_dir do
  repository node[id][:repository]
  revision node[id][:revision]
  enable_checkout false
  user node[id][:user]
  group node[id][:group]
  action :sync
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
  command 'npm run grunt'
  cwd base_dir
  user node[id][:user]
  group node[id][:group]
  environment 'HOME' => "/home/#{node[id][:user]}"
end

nginx_conf = ::File.join node[:nginx][:dir], 'sites-available', "#{node[id][:fqdn]}.conf"

template nginx_conf do
  Chef::Resource::Template.send(:include, ::ModernNginx::Helper)
  source 'nginx.conf.erb'
  mode 0644
  notifies :reload, 'service[nginx]', :delayed
  variables(
    fqdn: node[id][:fqdn],
    acme_challenge: node.chef_environment.start_with?('production'),
    acme_challenge_directories: {
      "#{node[id][:fqdn]}" => get_acme_challenge_directory(node[id][:fqdn]),
      "www.#{node[id][:fqdn]}" => get_acme_challenge_directory("www.#{node[id][:fqdn]}"),
      "2015.#{node[id][:fqdn]}" => get_acme_challenge_directory("2015.#{node[id][:fqdn]}")
    },
    ssl_certificate: get_ssl_certificate_path(node[id][:fqdn]),
    ssl_certificate_key: get_ssl_certificate_private_key_path(node[id][:fqdn]),
    hsts_max_age: node[id][:hsts_max_age],
    access_log: ::File.join(logs_dir, 'nginx_access.log'),
    error_log: ::File.join(logs_dir, 'nginx_error.log'),
    doc_root: ::File.join(base_dir, 'dist'),
    oscp_stapling: node.chef_environment.start_with?('production'),
    scts: node.chef_environment.start_with?('production'),
    scts_dir: get_scts_directory(node[id][:fqdn]),
    hpkp: node.chef_environment.start_with?('production'),
    hpkp_pins: get_hpkp_pins(node[id][:fqdn]),
    hpkp_max_age: node[id][:hpkp_max_age]
  )
  action :create
end

nginx_site "#{node[id][:fqdn]}.conf"
