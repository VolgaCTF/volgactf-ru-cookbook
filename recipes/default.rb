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

tls_rsa_certificate fqdn do
  action :deploy
end

tls_helper = ::ChefCookbook::TLS.new(node)
tls_rsa_item = tls_helper.rsa_certificate_entry(fqdn)
tls_ec_item = nil
ec_certificates = tls_helper.has_ec_certificate?(fqdn)

if ec_certificates
  tls_ec_certificate fqdn do
    action :deploy
  end

  tls_ec_item = tls_helper.ec_certificate_entry(fqdn)
end

ngx_vhost_variables = {
  fqdn: fqdn,
  ssl_rsa_certificate: tls_rsa_item.certificate_path,
  ssl_rsa_certificate_key: tls_rsa_item.certificate_private_key_path,
  hsts_max_age: node[id]['hsts_max_age'],
  access_log: ::File.join(node['nginx']['log_dir'], "#{fqdn}_access.log"),
  error_log: ::File.join(node['nginx']['log_dir'], "#{fqdn}_error.log"),
  doc_root: ::File.join(base_dir, 'build'),
  oscp_stapling: node[id]['oscp_stapling'],
  ec_certificates: ec_certificates
}

if ec_certificates
  ngx_vhost_variables.merge!({
    ssl_ec_certificate: tls_ec_item.certificate_path,
    ssl_ec_certificate_key: tls_ec_item.certificate_private_key_path
  })
end

nginx_site fqdn do
  template 'nginx.conf.erb'
  variables ngx_vhost_variables
  action :enable
end
