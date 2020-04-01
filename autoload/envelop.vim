" envelop/autoload/envelop.vim
"------------------------------------------------------------------------------"
"    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    "
"                                   envelop                                    "
"    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    "
"------------------------------------------------------------------------------"

"--------------------------------- Utilities ----------------------------------"
function! envelop#GetDefaultEnvs()

  " stock envs
  let l:defaults = {
    \ 'node': {
      \ 'commands': {
        \ 'create': ['npm', 'init', '-y'],
        \ 'install': ['npm', 'install'],
        \ 'update': ['npm', 'update'],
        \ },
      \ 'host_prog_target': 'node_modules/.bin/neovim-node-host',
      \ 'packages': [
        \ 'neovim',
        \ ],
      \ },
    \ 'python': {
      \ 'add_to_path': ['bin/python', 'bin/pip'],
      \ 'commands': {
        \ 'create': ['virtualenv', '.'],
        \ 'install': ['{vpath}bin/pip', 'install'],
        \ 'update': ['{vpath}bin/pip', 'install', '--upgrade'],
        \ },
      \ 'host_prog_target': 'bin/python',
      \ 'packages': [
        \ 'pip',
        \ 'pynvim',
        \ ],
      \ },
    \ 'python3': {
      \ 'add_to_path': ['bin/python3', 'bin/pip3'],
      \ 'commands': {
        \ 'create': ['python3', '-m', 'venv', '.'],
        \ 'install': ['{vpath}bin/pip3', 'install'],
        \ 'update': ['{vpath}bin/pip3', 'install', '--upgrade'],
        \ },
      \ 'host_prog_target': 'bin/python3',
      \ 'packages': [
        \ 'pip',
        \ 'pynvim',
        \ ],
      \ },
    \ }
    " \ 'perl': {},
    " \ 'ruby': {},

  let l:active = {}  " enabled + available = active
  for [provider, settings] in items(l:defaults)
    " only set defaults for providers that are installed
    if index(g:envelop_envs_enabled, provider) >= 0
      \ && executable(provider)
      let l:active[provider] = settings
    endif
  endfor
  return l:active

endfunction


function! s:get_env_path(name)
  return g:envelop_path . '/' . a:name
endfunction


function! s:get_bin_path()
  return g:envelop_path . '/bin'
endfunction

function! s:create_bin_dir()
  let l:envelop_bin_path = s:get_bin_path()
  if !isdirectory(l:envelop_bin_path)
    call mkdir(l:envelop_bin_path, 'p')
  endif
endfunction


function! s:sub_paths(name, settings)
  let l:dir = s:get_env_path(a:name)
  let l:settings = a:settings
  if has_key(l:settings, 'commands')
    for cmd in values(l:settings['commands'])
      call map(cmd, "substitute(v:val, '{vpath}', l:dir . '/', 'g')")
    endfor
  endif
  return l:settings
endfunction

function! s:get_env_settings(name)
  return s:sub_paths(a:name, g:envelop_envs[a:name])
endfunction


function! s:get_envelop_envs()
  return map(copy(g:envelop_envs), 's:sub_paths(v:key, v:val)')
endfunction


let s:jobs = {}
function! s:callback(job, code, event)
  let l:job = s:jobs[a:job]
  if a:code > 0
    echo printf('Failed to %s %s', l:job['action'], l:job['name'])
    return
  endif
  if l:job['action'] ==# 'create'
    echo printf('Added %s', l:job['name'])
    call s:install_packages(l:job['name'], l:job['settings'])
  elseif l:job['action'] ==# 'install'
    echo printf('Installed packages for %s', l:job['name'])
    call s:link_bins(l:job['name'], l:job['settings'])
  elseif l:job['action'] ==# 'update'
    echo printf('Updated packages for %s', l:job['name'])
  elseif l:job['action'] ==# 'link'
    echo printf('Linked bins for %s', l:job['name'])
  endif
  unlet s:jobs[a:job]
  if len(s:jobs) == 0
    echo 'Envelop job complete'
  endif
endfunction


function! s:create_env(name, settings)
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


function! s:install_packages(name, settings)
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


function! s:update_packages(name, settings)
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


function! s:link_bins(name, settings)
  if !has_key(a:settings, 'add_to_path') || !executable('ln')
    return
  endif
  call s:create_bin_dir()
  let l:envelop_bin_path = s:get_bin_path()
  for src in a:settings['add_to_path']
    let l:src = s:get_env_path(a:name) . '/' . src
    let l:target = l:envelop_bin_path . '/' . split(src, '/')[-1]
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
function! envelop#CreateEnvs()
  let l:envelop_envs = s:get_envelop_envs()
  call map(l:envelop_envs, 's:create_env(v:key, v:val)')
endfunction


function! envelop#UpdateEnvs()
  let l:envelop_envs = s:get_envelop_envs()
  call map(l:envelop_envs, 's:update_packages(v:key, v:val)')
endfunction


function! envelop#DestroyEnvs()
  call delete(g:envelop_path, 'rf')
  echo 'Destroyed envelop envs'
endfunction


"------------------------------ Provider Globals ------------------------------"
function! envelop#SetHostProgGlobals()
  for [name, settings] in items(g:envelop_envs)
    if has_key(settings, 'host_prog_target')
      let l:target_path =
        \ s:get_env_path(name) . '/' . settings['host_prog_target']
      if filereadable(l:target_path)
        let l:host_prog_var = name . '_host_prog'
        let g:[l:host_prog_var] = l:target_path
      endif
    endif
  endfor
endfunction


"----------------------------------- $PATH ------------------------------------"
function! envelop#addBinsToPath()
  call s:create_bin_dir()
  let $PATH .= ':' . s:get_bin_path()
endfunction


function! envelop#LinkBins()
  call s:create_bin_dir()
  call map(s:get_envelop_envs(), 's:link_bins(v:key, v:val)')
endfunction


function! envelop#UnlinkBins()
  let l:envelop_bin_path = g:envelop_path . '/bin'
  call delete(l:envelop_bin_path, 'rf')
endfunction


function! envelop#RelinkBins()
  call envelop#UnlinkBins()
  call envelop#LinkBins()
endfunction
