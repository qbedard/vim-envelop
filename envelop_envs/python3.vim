call envelop#Set('python3_packages', ['pip', 'pynvim'])
let s:link = envelop#Set('python3_link', ['bin/pip3', 'bin/python3'])
let s:set_host_prog = envelop#Set('python3_set_host_prog', 1)

let s:env_path = envelop#GetEnvPath('python3')


if envelop#Var('set_host_prog') && s:set_host_prog
  let g:python3_host_prog = envelop#GetEnvPath('python3') . '/bin/python3'
endif


function! envelop_envs#python3#Install() abort
  return
    \ [s:env_path . '/bin/pip3', 'install'] +
    \ envelop#Var('python3_packages')
endfunction


function! envelop_envs#python3#Update() abort
  return
    \ [s:env_path . '/bin/pip3', 'install', '--upgrade'] +
    \ envelop#Var('python3_packages')
endfunction


call envelop#AddEnv('python3', {
  \ 'commands': {
    \ 'create': ['python3', '-m', 'venv', s:env_path],
    \ 'install': function('envelop_envs#python3#Install'),
    \ 'update': function('envelop_envs#python3#Update'),
    \ },
  \ 'link': s:link,
  \ })
