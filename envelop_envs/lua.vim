call envelop#Set('lua_packages', [])
call envelop#Set('lua_server', 'http://luarocks.org/dev')
call envelop#Set('lua_set_lua_path', 1)
call envelop#Set('lua_version', '5.4')
let s:link = envelop#Set('lua_link', [])

let s:env_path = envelop#GetEnvPath('lua')

if envelop#Var('lua_set_lua_path')
  let $LUA_PATH = s:env_path . '/?.lua'
  let $LUA_CPATH = s:env_path . '/?.so'
endif

let s:luarocks_cmd = [
  \ 'luarocks',
  \ ' --lua-version', envelop#Var('lua_version'),
  \ '--server', envelop#Var('lua_server'),
  \ ]

let s:luarocks_create_cmd =
  \ join(s:luarocks_cmd, ' ') .
  \ ' init' .
  \ ' && luarocks-admin make_manifest --local-tree'


function! envelop_envs#lua#Install() abort
  let s:install_cmds = []
  for package in envelop#Var('lua_packages')
    call add(s:install_cmds, join(s:luarocks_cmd + ['install', package], ' '))
  endfor
  return join(s:install_cmds, '&&')
endfunction


call envelop#AddEnv('lua', {
  \ 'commands': {
    \ 'create': s:luarocks_create_cmd,
    \ 'install': function('envelop_envs#lua#Install'),
    \ 'update': function('envelop_envs#lua#Install'),
    \ },
  \ 'link': s:link,
  \ })
