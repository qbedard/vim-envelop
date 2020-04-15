call envelop#Set('python_packages', ['pip', 'pynvim'])
let s:link = envelop#Set('python_link', ['bin/pip', 'bin/python'])
let s:set_host_prog = envelop#Set('python_set_host_prog', 1)

let s:env_path = envelop#GetEnvPath('python')


if envelop#Var('set_host_prog') && s:set_host_prog
  let g:python_host_prog = envelop#GetEnvPath('python') . '/bin/python'
endif


function! envelop_envs#python#Install() abort
  return
    \ [s:env_path . '/bin/pip', 'install'] +
    \ envelop#Var('python_packages')
endfunction


function! envelop_envs#python#Update() abort
  return
    \ [s:env_path . '/bin/pip', 'install', '--upgrade'] +
    \ envelop#Var('python_packages')
endfunction


call envelop#AddEnv('python', {
  \ 'commands': {
    \ 'create': ['virtualenv', s:env_path],
    \ 'install': function('envelop_envs#python#Install'),
    \ 'update': function('envelop_envs#python#Update'),
    \ },
  \ 'link': s:link,
  \ })
