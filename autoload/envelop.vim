" envelop/autoload/envelop.vim
"------------------------------------------------------------------------------"
"    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    "
"                                 vim-envelop                                  "
"    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    "
"------------------------------------------------------------------------------"

"------------------------------------ Jobs ------------------------------------"
let s:jobs = {}


function! envelop#Callback(job, code, event) abort
  let l:job = s:jobs[a:job]
  if a:code > 0
    echo printf('Failed to %s %s', l:job['action'], l:job['name'])
  elseif l:job['action'] is# 'create'
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


"--------------------------------- Variables ----------------------------------"
" TODO: Combine Set() and Var()?
function! envelop#Set(variable_name, default) abort
  let l:full_name = 'envelop_' . a:variable_name
  if !has_key(g:, l:full_name)
    let g:[l:full_name] = a:default
  endif
  return g:[l:full_name]
endfunction


function! envelop#Var(variable_name) abort
    let l:full_name = 'envelop_' . a:variable_name
    return g:[l:full_name]
endfunction


"----------------------------------- Paths ------------------------------------"
function! envelop#GetEnvPath(name) abort
  return g:envelop_path . '/' . a:name
endfunction


function! envelop#GetLinkPath(...) abort
  let l:name = get(a:, 1, '')
  let l:path = g:envelop_path . '/bin'
  if len(l:name)
    let l:path .= '/' . l:name
  endif
  return l:path
endfunction


function! envelop#CreateEnvelopDir() abort
  if !isdirectory(g:envelop_path)
    call mkdir(g:envelop_path, 'p')
  endif
endfunction


function! envelop#CreateLinkDir() abort
  let l:envelop_link_path = envelop#GetLinkPath()
  if !isdirectory(l:envelop_link_path)
    call mkdir(l:envelop_link_path, 'p')
  endif
endfunction


function! envelop#CreateLinks(name, settings) abort
  if !has_key(a:settings, 'link') || !executable('ln')
    " TODO: error here?
    return
  endif
  call envelop#CreateLinkDir()
  for src in a:settings['link']
    let l:src = envelop#GetEnvPath(a:name) . '/' . src
    let l:target = envelop#GetLinkPath(split(src, '/')[-1])
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


function! envelop#AddLinksToPath() abort
  call envelop#CreateLinkDir()
  let $PATH .= ':' . envelop#GetLinkPath()
endfunction


function! envelop#Link() abort
  call envelop#CreateLinkDir()
  call map(copy(g:envelop_envs), 'envelop#CreateLinks(v:key, v:val)')
endfunction


function! envelop#Unlink() abort
  let l:envelop_link_path = envelop#GetLinkPath()
  call delete(l:envelop_link_path, 'rf')
endfunction


function! envelop#Relink() abort
  call envelop#Unlink()
  call envelop#Link()
endfunction


"------------------------------------ Envs ------------------------------------"
function! envelop#AddEnv(name, definition) abort
  if !has_key(g:envelop_envs, a:name)
    let g:envelop_envs[a:name] = a:definition
  else
    " TODO: error?
  endif
endfunction


" TODO: Rename?
" function! envelop#UpdateEnvs(definitions) abort
"   call extend(envelop#Var('envs'), a:definitions)
" endfunction


function! envelop#GetEnv(name) abort
  return g:envelop_envs[a:name]
endfunction


function! envelop#LoadEnv(name) abort
  execute 'silent! runtime! envelop_envs/' . a:name . '.vim'
endfunction


function! envelop#CreateEnv(name, settings) abort
  call envelop#CreateEnvelopDir()
  if !has_key(a:settings, 'commands')
    \ || !has_key(a:settings['commands'], 'create')
    return
  endif
  let l:dir = envelop#GetEnvPath(a:name)
  if !isdirectory(l:dir)
    call mkdir(l:dir, 'p')
  endif
  let l:Cmd = a:settings['commands']['create']
  let l:job_id = jobstart(
    \ type(l:Cmd) is v:t_func ? l:Cmd() : l:Cmd,
    \ {'cwd': l:dir, 'on_exit': function('envelop#Callback')},
    \ )
  let s:jobs[l:job_id] = {
    \ 'action': 'create',
    \ 'name': a:name,
    \ 'settings': a:settings,
    \ }
endfunction


function! envelop#InstallPackages(name, settings) abort
  if !has_key(a:settings, 'commands')
    \ || !has_key(a:settings['commands'], 'install')
    return
  endif
  let l:dir = envelop#GetEnvPath(a:name)
  let l:Cmd = a:settings['commands']['install']
  let l:job_id = jobstart(
      \ type(l:Cmd) is v:t_func ? l:Cmd() : l:Cmd,
    \ {'cwd': l:dir, 'on_exit': function('envelop#Callback')}
    \ )
  let s:jobs[l:job_id] = {
    \ 'action': 'install',
    \ 'name': a:name,
    \ 'settings': a:settings,
    \ }
endfunction


function! envelop#UpdatePackages(name, settings) abort
  if !has_key(a:settings, 'commands')
    \ || !has_key(a:settings['commands'], 'update')
    return
  endif
  let l:dir = envelop#GetEnvPath(a:name)
  let l:Cmd = a:settings['commands']['update']
  let l:job_id = jobstart(
    \ type(l:Cmd) is v:t_func ? l:Cmd() : l:Cmd,
    \ {'cwd': l:dir, 'on_exit': function('envelop#Callback')}
    \ )
  let s:jobs[l:job_id] = {
    \ 'action': 'update',
    \ 'name': a:name,
    \ 'settings': a:settings,
    \ }
endfunction


"------------------------------ Env Management -------------------------------"
function! envelop#CreateEnvs() abort
  call map(copy(g:envelop_envs), 'envelop#CreateEnv(v:key, v:val)')
endfunction


function! envelop#InstallEnvPackages() abort
  call map(copy(g:envelop_envs), 'envelop#InstallPackages(v:key, v:val)')
endfunction


function! envelop#UpdateEnvs() abort
  call map(copy(g:envelop_envs), 'envelop#UpdatePackages(v:key, v:val)')
endfunction


function! envelop#DestroyEnvs() abort
  call delete(g:envelop_path, 'rf')
  echo 'Destroyed envelop envs'
endfunction
