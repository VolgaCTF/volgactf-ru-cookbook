id = 'volgactf-ru'

default[id][:user] = 'vagrant'
default[id][:group] = 'vagrant'
default[id][:fqdn] = 'volgactf.dev'

default[id][:repository] = 'https://github.com/VolgaCTF/volgactf.ru'
default[id][:revision] = 'master'

default[id][:hsts_max_age] = 15768000
default[id][:hpkp_max_age] = 604800

