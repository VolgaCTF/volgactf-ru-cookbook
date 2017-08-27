id = 'volgactf-ru'

h = ::ChefCookbook::Instance::Helper.new(node)

fqdn = node[id]['fqdn']
base_dir = ::File.join('/var/www', fqdn)
is_development = node.chef_environment.start_with?('development')

directory base_dir do
  owner h.instance_user
  group h.instance_group
  mode 0755
  recursive true
  action :create
end

repository_url = "https://github.com/#{node[id]['github_repository']}"

git base_dir do
  repository repository_url
  revision node[id]['revision']
  enable_checkout false
  user h.instance_user
  group h.instance_group
  action :sync
end

nodejs_npm "Install npm packages at #{base_dir}" do
  package '.'
  path base_dir
  json true
  user h.instance_user
  group h.instance_group
end

execute "Build assets at #{base_dir}" do
  command 'npm run build'
  cwd base_dir
  user h.instance_user
  group h.instance_group
  environment(
    'HOME' => h.instance_user_home,
    'NODE_ENV' => node.chef_environment
  )
end

tls_certificate fqdn do
  action :deploy
end

tls_item = ::ChefCookbook::TLS.new(node).certificate_entry(fqdn)

nginx_site fqdn do
  template 'nginx.conf.erb'
  variables(
    fqdn: fqdn,
    ssl_certificate: tls_item.certificate_path,
    ssl_certificate_key: tls_item.certificate_private_key_path,
    hsts_max_age: node[id]['hsts_max_age'],
    access_log: ::File.join(node['nginx']['log_dir'], "#{fqdn}_access.log"),
    error_log: ::File.join(node['nginx']['log_dir'], "#{fqdn}_error.log"),
    doc_root: ::File.join(base_dir, 'build'),
    oscp_stapling: !is_development,
    scts: !is_development,
    scts_dir: tls_item.scts_dir,
    hpkp: !is_development,
    hpkp_pins: tls_item.hpkp_pins,
    hpkp_max_age: node[id]['hpkp_max_age']
  )
  action :enable
end
