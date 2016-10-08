require 'etc'

id = 'volgactf-ru'

fqdn = node[id]['main']['fqdn']
base_dir = ::File.join('/var/www', fqdn)
is_development = node.chef_environment.start_with?('development')
instance_user = node[id]['user']
instance_user_home = ::Etc.getpwnam(instance_user).dir
instance_group = ::Etc.getgrgid(::Etc.getpwnam(instance_user).gid).name

directory base_dir do
  owner instance_user
  group instance_group
  mode 0755
  recursive true
  action :create
end

if is_development
  ssh_private_key instance_user
  ssh_known_hosts_entry 'github.com'
end

repository_url = \
  if is_development
    "git@github.com:#{node[id]['main']['github_repository']}.git"
  else
    "https://github.com/#{node[id]['main']['github_repository']}"
  end

git2 base_dir do
  url repository_url
  branch node[id]['main']['revision']
  user instance_user
  group instance_group
  action :create
end

if is_development
  data_bag_item('git', node.chef_environment).to_hash.fetch('config', {}).each do |key, value|
    git_config key do
      value value
      scope 'local'
      path base_dir
      user instance_group
      action :set
    end
  end
end

logs_dir = ::File.join base_dir, 'logs'

directory logs_dir do
  owner instance_user
  group instance_group
  mode 0755
  recursive true
  action :create
end

nodejs_npm "Install npm packages at #{base_dir}" do
  package '.'
  path base_dir
  json true
  user instance_user
  group instance_group
end

execute "Install Bower packages at #{base_dir}" do
  command 'npm run bower -- install'
  cwd base_dir
  user instance_user
  group instance_group
  environment 'HOME' => instance_user_home
end

execute "Build assets at #{base_dir}" do
  command 'npm run grunt'
  cwd base_dir
  user instance_user
  group instance_group
  environment 'HOME' => instance_user_home
end

tls_certificate fqdn do
  action :deploy
end

ngx_cnf = "#{fqdn}.conf"
tls_item = ::ChefCookbook::TLS.new(node).certificate_entry fqdn

template ::File.join(node['nginx']['dir'], 'sites-available', ngx_cnf) do
  source 'main.conf.erb'
  mode 0644
  notifies :reload, 'service[nginx]', :delayed
  variables(
    fqdn: fqdn,
    ssl_certificate: tls_item.certificate_path,
    ssl_certificate_key: tls_item.certificate_private_key_path,
    hsts_max_age: node[id]['hsts_max_age'],
    access_log: ::File.join(logs_dir, 'nginx_access.log'),
    error_log: ::File.join(logs_dir, 'nginx_error.log'),
    doc_root: ::File.join(base_dir, 'dist'),
    oscp_stapling: !is_development,
    scts: !is_development,
    scts_dir: tls_item.scts_dir,
    hpkp: !is_development,
    hpkp_pins: tls_item.hpkp_pins,
    hpkp_max_age: node[id]['hpkp_max_age']
  )
  action :create
end

nginx_site ngx_cnf
