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


function! envelop#GetEnvPath(name) abort
  return g:envelop_path . '/' . a:name
endfunction


function! envelop#GetLinkPath() abort
  return g:envelop_path . '/bin'
endfunction


function! envelop#CreateLinkDir() abort
  let l:envelop_link_path = envelop#GetLinkPath()
  if !isdirectory(l:envelop_link_path)
    call mkdir(l:envelop_link_path, 'p')
  endif
endfunction


function! envelop#SubPaths(name, settings) abort
  let l:dir = envelop#GetEnvPath(a:name)
  let l:settings = a:settings
  if has_key(l:settings, 'commands')
    for cmd in values(l:settings['commands'])
      call map(cmd, "substitute(v:val, '{vpath}', l:dir . '/', 'g')")
    endfor
  endif
  return l:settings
endfunction

function! envelop#GetEnvSettings(name) abort
  return envelop#SubPaths(a:name, g:envelop_envs[a:name])
endfunction


function! envelop#GetEnvelopEnvs() abort
  return map(copy(g:envelop_envs), 'envelop#SubPaths(v:key, v:val)')
endfunction


let s:jobs = {}
function! envelop#Callback(job, code, event) abort
  let l:job = s:jobs[a:job]
  if a:code > 0
    echo printf('Failed to %s %s', l:job['action'], l:job['name'])
    return
  endif
  if l:job['action'] is# 'create'
    echo printf('Added %s', l:job['name'])
    call envelop#InstallPackages(l:job['name'], l:job['settings'])
  elseif l:job['action'] is# 'install'
    echo printf('Installed packages for %s', l:job['name'])
    call envelop#CreateLinks(l:job['name'], l:job['settings'])
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


function! envelop#CreateEnv(name, settings) abort
  if has_key(a:settings, 'commands')
    \ && has_key(a:settings['commands'], 'create')
    let l:dir = envelop#GetEnvPath(a:name)
    if !isdirectory(l:dir)
      call mkdir(l:dir, 'p')
    endif
    let l:job_id = jobstart(
      \ a:settings['commands']['create'],
      \ {'cwd': l:dir, 'on_exit': function('envelop#Callback')},
      \ )
    let s:jobs[l:job_id] = {
      \ 'action': 'create',
      \ 'name': a:name,
      \ 'settings': a:settings,
      \ }
  endif
endfunction


function! envelop#InstallPackages(name, settings) abort
  if !has_key(a:settings, 'packages')
    \ || !has_key(a:settings, 'commands')
    \ || !has_key(a:settings['commands'], 'install')
    return
  endif
  let l:cmd = a:settings['commands']['install'] + a:settings['packages']
  let l:dir = envelop#GetEnvPath(a:name)
  let l:job_id = jobstart(
    \ l:cmd,
    \ {'cwd': l:dir, 'on_exit': function('envelop#Callback')}
    \ )
  let s:jobs[l:job_id] = {
    \ 'action': 'install',
    \ 'name': a:name,
    \ 'settings': a:settings,
    \ }
endfunction


function! envelop#UpdatePackages(name, settings) abort
  let l:settings = envelop#GetEnvSettings(a:name)
  if !has_key(l:settings, 'packages')
    \ || !has_key(l:settings, 'commands')
    \ || !has_key(l:settings['commands'], 'update')
    return
  endif
  let l:cmd = l:settings['commands']['update'] + l:settings['packages']
  let l:dir = envelop#GetEnvPath(a:name)
  let l:job_id = jobstart(
    \ l:cmd,
    \ {'cwd': l:dir, 'on_exit': function('envelop#Callback')}
    \ )
  let s:jobs[l:job_id] = {
    \ 'action': 'update',
    \ 'name': a:name,
    \ 'settings': a:settings,
    \ }
endfunction


function! envelop#CreateLinks(name, settings) abort
  if !has_key(a:settings, 'link') || !executable('ln')
    return
  endif
  call envelop#CreateLinkDir()
  let l:envelop_link_path = envelop#GetLinkPath()
  for src in a:settings['link']
    let l:src = envelop#GetEnvPath(a:name) . '/' . src
    let l:target = l:envelop_link_path . '/' . split(src, '/')[-1]
    if filereadable(l:src) && !filereadable(l:target)
      let l:job_id = jobstart(
        \ ['ln', '-s', l:src, l:target],
        \ {'on_exit': function('envelop#Callback')}
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
  let l:envelop_envs = envelop#GetEnvelopEnvs()
  call map(l:envelop_envs, 'envelop#CreateEnv(v:key, v:val)')
endfunction


function! envelop#UpdateEnvs() abort
  let l:envelop_envs = envelop#GetEnvelopEnvs()
  call map(l:envelop_envs, 'envelop#UpdatePackages(v:key, v:val)')
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
        \ envelop#GetEnvPath(name) . '/' . settings['host_prog']
      if filereadable(l:target_path)
        let l:host_prog_var = name . '_host_prog'
        let g:[l:host_prog_var] = l:target_path
      endif
    endif
  endfor
endfunction


"----------------------------------- $PATH ------------------------------------"
function! envelop#AddLinksToPath() abort
  call envelop#CreateLinkDir()
  let $PATH .= ':' . envelop#GetLinkPath()
endfunction


function! envelop#Link() abort
  call envelop#CreateLinkDir()
  call map(envelop#GetEnvelopEnvs(), 'envelop#CreateLinks(v:key, v:val)')
endfunction


function! envelop#Unlink() abort
  let l:envelop_link_path = envelop#GetLinkPath()
  call delete(l:envelop_link_path, 'rf')
endfunction


function! envelop#Relink() abort
  call envelop#Unlink()
  call envelop#Link()
endfunction
