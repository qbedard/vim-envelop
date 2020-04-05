" envelop/autoload/envelop.vim
"------------------------------------------------------------------------------"
"    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    "
"                                   envelop                                    "
"    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    "
"------------------------------------------------------------------------------"

"--------------------------------- Constants ----------------------------------"
let s:default_envs = {
  \ 'node': {
    \ 'commands': {
      \ 'create': ['npm', 'init', '-y'],
      \ 'install': ['npm', 'install'],
      \ 'update': ['npm', 'update'],
      \ },
    \ 'host_prog': 'node_modules/.bin/neovim-node-host',
    \ 'packages': [
      \ 'neovim',
      \ ],
    \ },
  \ 'python': {
    \ 'commands': {
      \ 'create': ['virtualenv', '.'],
      \ 'install': ['{vpath}bin/pip', 'install'],
      \ 'update': ['{vpath}bin/pip', 'install', '--upgrade'],
      \ },
    \ 'host_prog': 'bin/python',
    \ 'link': ['bin/python', 'bin/pip'],
    \ 'packages': [
      \ 'pip',
      \ 'pynvim',
      \ ],
    \ },
  \ 'python3': {
    \ 'commands': {
      \ 'create': ['python3', '-m', 'venv', '.'],
      \ 'install': ['{vpath}bin/pip3', 'install'],
      \ 'update': ['{vpath}bin/pip3', 'install', '--upgrade'],
      \ },
    \ 'host_prog': 'bin/python3',
    \ 'link': ['bin/python3', 'bin/pip3'],
    \ 'packages': [
      \ 'pip',
      \ 'pynvim',
      \ ],
    \ },
  \ }
  " \ 'perl': {},
  " \ 'ruby': {},

"--------------------------------- Utilities ----------------------------------"
function! envelop#AddProviderEnvs() abort
endfunction


function! envelop#GetDefaultEnvs() abort
  let l:active = {}  " enabled + available = active
  for [provider, settings] in items(s:default_envs)
    " only set defaults for providers that are installed
    if index(g:envelop_envs_enabled, provider) >= 0
      \ && executable(provider)
      let l:active[provider] = settings
    endif
  endfor
  return l:active
endfunction


function! s:get_env_path(name) abort
  return g:envelop_path . '/' . a:name
endfunction


function! s:get_link_path() abort
  return g:envelop_path . '/bin'
endfunction


function! s:create_link_dir() abort
  let l:envelop_link_path = s:get_link_path()
  if !isdirectory(l:envelop_link_path)
    call mkdir(l:envelop_link_path, 'p')
  endif
endfunction


function! s:sub_paths(name, settings) abort
  let l:dir = s:get_env_path(a:name)
  let l:settings = a:settings
  if has_key(l:settings, 'commands')
    for cmd in values(l:settings['commands'])
      call map(cmd, "substitute(v:val, '{vpath}', l:dir . '/', 'g')")
    endfor
  endif
  return l:settings
endfunction

function! s:get_env_settings(name) abort
  return s:sub_paths(a:name, g:envelop_envs[a:name])
endfunction


function! s:get_envelop_envs() abort
  return map(copy(g:envelop_envs), 's:sub_paths(v:key, v:val)')
endfunction


let s:jobs = {}
function! s:callback(job, code, event) abort
  let l:job = s:jobs[a:job]
  if a:code > 0
    echo printf('Failed to %s %s', l:job['action'], l:job['name'])
    return
  endif
  if l:job['action'] is# 'create'
    echo printf('Added %s', l:job['name'])
    call s:install_packages(l:job['name'], l:job['settings'])
  elseif l:job['action'] is# 'install'
    echo printf('Installed packages for %s', l:job['name'])
    call s:create_links(l:job['name'], l:job['settings'])
  elseif l:job['action'] is# 'update'
    echo printf('Updated packages for %s', l:job['name'])
  elseif l:job['action'] is# 'link'
    echo printf('Linked %s', l:job['name'])
  endif
  unlet s:jobs[a:job]
  if len(s:jobs) == 0
    echo 'Envelop job complete'
  endif
endfunction


function! s:create_env(name, settings) abort
  if has_key(a:settings, 'commands')
    \ && has_key(a:settings['commands'], 'create')
    let l:dir = s:get_env_path(a:name)
    if !isdirectory(l:dir)
      call mkdir(l:dir, 'p')
    endif
    let l:job_id = jobstart(
      \ a:settings['commands']['create'],
      \ {'cwd': l:dir, 'on_exit': function('s:callback')},
      \ )
    let s:jobs[l:job_id] = {
      \ 'action': 'create',
      \ 'name': a:name,
      \ 'settings': a:settings,
      \ }
  endif
endfunction


function! s:install_packages(name, settings) abort
  if !has_key(a:settings, 'packages')
    \ || !has_key(a:settings, 'commands')
    \ || !has_key(a:settings['commands'], 'install')
    return
  endif
  let l:cmd = a:settings['commands']['install'] + a:settings['packages']
  let l:dir = s:get_env_path(a:name)
  let l:job_id = jobstart(
    \ l:cmd,
    \ {'cwd': l:dir, 'on_exit': function('s:callback')}
    \ )
  let s:jobs[l:job_id] = {
    \ 'action': 'install',
    \ 'name': a:name,
    \ 'settings': a:settings,
    \ }
endfunction


function! s:update_packages(name, settings) abort
  let l:settings = s:get_env_settings(a:name)
  if !has_key(l:settings, 'packages')
    \ || !has_key(l:settings, 'commands')
    \ || !has_key(l:settings['commands'], 'update')
    return
  endif
  let l:cmd = l:settings['commands']['update'] + l:settings['packages']
  let l:dir = s:get_env_path(a:name)
  let l:job_id = jobstart(
    \ l:cmd,
    \ {'cwd': l:dir, 'on_exit': function('s:callback')}
    \ )
  let s:jobs[l:job_id] = {
    \ 'action': 'update',
    \ 'name': a:name,
    \ 'settings': a:settings,
    \ }
endfunction


function! s:create_links(name, settings) abort
  if !has_key(a:settings, 'link') || !executable('ln')
    return
  endif
  call s:create_link_dir()
  let l:envelop_link_path = s:get_link_path()
  for src in a:settings['link']
    let l:src = s:get_env_path(a:name) . '/' . src
    let l:target = l:envelop_link_path . '/' . split(src, '/')[-1]
    if filereadable(l:src) && !filereadable(l:target)
      let l:job_id = jobstart(
        \ ['ln', '-s', l:src, l:target],
        \ {'on_exit': function('s:callback')}
        \ )
      let s:jobs[l:job_id] = {
        \ 'action': 'link',
        \ 'name': a:name,
        \ 'settings': a:settings,
        \ }
    endif
  endfor
endfunction


"------------------------------ Env Management -------------------------------"
function! envelop#CreateEnvs() abort
  let l:envelop_envs = s:get_envelop_envs()
  call map(l:envelop_envs, 's:create_env(v:key, v:val)')
endfunction


function! envelop#UpdateEnvs() abort
  let l:envelop_envs = s:get_envelop_envs()
  call map(l:envelop_envs, 's:update_packages(v:key, v:val)')
endfunction


function! envelop#DestroyEnvs() abort
  call delete(g:envelop_path, 'rf')
  echo 'Destroyed envelop envs'
endfunction


"------------------------------ Provider Globals ------------------------------"
function! envelop#SetHostProgGlobals() abort
  for [name, settings] in items(g:envelop_envs)
    if has_key(settings, 'host_prog')
      let l:target_path =
        \ s:get_env_path(name) . '/' . settings['host_prog']
      if filereadable(l:target_path)
        let l:host_prog_var = name . '_host_prog'
        let g:[l:host_prog_var] = l:target_path
      endif
    endif
  endfor
endfunction


"----------------------------------- $PATH ------------------------------------"
function! envelop#AddLinksToPath() abort
  call s:create_link_dir()
  let $PATH .= ':' . s:get_link_path()
endfunction


function! envelop#Link() abort
  call s:create_link_dir()
  call map(s:get_envelop_envs(), 's:create_links(v:key, v:val)')
endfunction


function! envelop#Unlink() abort
  let l:envelop_link_path = s:get_link_path()
  call delete(l:envelop_link_path, 'rf')
endfunction


function! envelop#Relink() abort
  call envelop#Unlink()
  call envelop#Link()
endfunction
