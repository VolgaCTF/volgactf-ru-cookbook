id = 'volgactf-ru'

default[id][:user] = 'vagrant'
default[id][:group] = 'vagrant'

default[id][:main][:fqdn] = 'volgactf.dev'
default[id][:main][:repository] = 'https://github.com/VolgaCTF/volgactf.ru'
default[id][:main][:revision] = 'master'

default[id][:arch_2015][:fqdn] = '2015.volgactf.dev'
default[id][:arch_2015][:repository] = 'https://github.com/VolgaCTF/2015.volgactf.ru'
default[id][:arch_2015][:revision] = 'master'

default[id][:hsts_max_age] = 15768000
default[id][:hpkp_max_age] = 604800
