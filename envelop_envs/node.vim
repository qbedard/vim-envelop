call envelop#Set('node_packages', ['neovim'])
let s:link = envelop#Set('node_link', [])
let s:set_host_prog = envelop#Set('node_set_host_prog', 1)

let s:env_path = envelop#GetEnvPath('node')


if envelop#Var('set_host_prog') && s:set_host_prog
  let g:node_host_prog =
    \ envelop#GetEnvPath('node') .
    \ '/node_modules/.bin/neovim-node-host'
endif


function! envelop_envs#node#Install() abort
  return ['npm', 'install'] + envelop#Var('node_packages')
endfunction


call envelop#AddEnv('node', {
  \ 'commands': {
    \ 'create': ['npm', 'init', '-y'],
    \ 'install': function('envelop_envs#node#Install'),
    \ 'update': ['npm', 'update'],
    \ },
  \ 'link': s:link,
  \ })
