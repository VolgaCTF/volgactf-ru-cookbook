id = 'volgactf-ru'

instance = ::ChefCookbook::Instance::Helper.new(node)

fqdn = node[id]['fqdn']
base_dir = ::File.join('/var/www', fqdn)

directory base_dir do
  owner instance.user
  group instance.group
  mode 0755
  recursive true
  action :create
end

repository_url = "https://github.com/#{node[id]['github_repository']}"

git base_dir do
  repository repository_url
  revision node[id]['revision']
  enable_checkout false
  user instance.user
  group instance.group
  action :sync
end

nodejs_npm "Install npm packages at #{base_dir}" do
  package '.'
  path base_dir
  json true
  user instance.user
  group instance.group
end

execute "Build assets at #{base_dir}" do
  command 'npm run build'
  cwd base_dir
  user instance.user
  group instance.group
  environment(
    'HOME' => instance.user_home,
    'NODE_ENV' => node.chef_environment
  )
end

ngx_vhost_variables = {
  fqdn: fqdn,
  doc_root: ::File.join(base_dir, 'build'),
  hsts_max_age: node[id]['hsts_max_age'],
  oscp_stapling: node[id]['oscp_stapling'],
  resolvers: %w[1.1.1.1 8.8.8.8 1.0.0.1 8.8.4.4],
  resolver_valid: 600,
  resolver_timeout: 10,
  certificate_entries: []
}

tls_rsa_certificate fqdn do
  action :deploy
end

tls_helper = ::ChefCookbook::TLS.new(node)
ngx_vhost_variables[:certificate_entries] << tls_helper.rsa_certificate_entry(fqdn)

if tls_helper.has_ec_certificate?(fqdn)
  tls_ec_certificate fqdn do
    action :deploy
  end

  ngx_vhost_variables[:certificate_entries] << tls_helper.ec_certificate_entry(fqdn)
end

nginx_vhost fqdn do
  template 'nginx.conf.erb'
  variables(lazy {
    ngx_vhost_variables.merge(
      access_log: ::File.join(node.run_state['nginx']['log_dir'], "#{fqdn}_access.log"),
      error_log: ::File.join(node.run_state['nginx']['log_dir'], "#{fqdn}_error.log")
    )
  })
  action :enable
end
