" envelop/autoload/envelop.vim
"-----------------------------------------------------------------------------"
"    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    "
"                                   envelop                                   "
"    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    "
"-----------------------------------------------------------------------------"

"--------------------------------- Utilities ----------------------------------"
function! envelop#GetDefaultEnvs()

  " stock venvs
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


function! s:get_venv_path(name)
  return g:envelop_path . '/' . a:name
endfunction


function! s:get_envelop_envs()
  let l:envelop_envs = g:envelop_envs
  for [name, settings] in items(l:envelop_envs)
    let l:dir = s:get_venv_path(name)
    if has_key(settings, 'commands')
      for cmd in values(settings['commands'])
        call map(cmd, "substitute(v:val, '{vpath}', l:dir . '/', 'g')")
      endfor
    endif
  endfor
  return l:envelop_envs
endfunction


"------------------------------ Venv Management -------------------------------"
function! envelop#CreateVenvs()

  " get venv path-substitutted envelop_envs dict
  let l:envelop_envs = s:get_envelop_envs()

  for [name, settings] in items(l:envelop_envs)

    " create dir
    let l:dir = s:get_venv_path(name)
    call mkdir(l:dir, 'p')

    if has_key(settings, 'commands')

      " create venv
      let l:create_jobs = []
      if has_key(settings['commands'], 'create')
        call add(l:create_jobs,
          \ jobstart(
            \ settings['commands']['create'],
            \ {'cwd': l:dir}
            \ )
          \ )
      endif

      " TODO: refactor this to install nvim with callback instead
      call jobwait(l:create_jobs)

      " install packages
      if has_key(settings['commands'], 'install')
        \ && has_key(settings, 'packages')
        let l:cmd = settings['commands']['install']
        let l:cmd += settings['packages']
        call jobstart(l:cmd, {'cwd': l:dir})
      endif

    endif

  endfor

  " link bins
  if g:envelop_add_to_path && executable('ln')
    call envelop#LinkBins()
  endif

endfunction


function! envelop#UpdateVenvs()

  " get venv path-substitutted envelop_envs dict
  let l:envelop_envs = s:get_envelop_envs()

  for [name, settings] in items(l:envelop_envs)
    if has_key(settings, 'commands')
      \ && has_key(settings['commands'], 'update')

      " update packages
      let l:cmd = settings['commands']['update']
      let l:cmd += settings['packages']
      call jobstart(l:cmd, {'cwd': s:get_venv_path(name)})

    endif
  endfor

endfunction

"------------------------------ Provider Globals ------------------------------"
function! envelop#SetHostProgGlobals()
  for [name, settings] in items(g:envelop_envs)
    if has_key(settings, 'host_prog_target')
      let l:target_path =
        \ s:get_venv_path(name) . '/' . settings['host_prog_target']
      if filereadable(l:target_path)
        let l:host_prog_var = name . '_host_prog'
        let g:[l:host_prog_var] = l:target_path
      endif
    endif
  endfor
endfunction


"----------------------------------- $PATH ------------------------------------"
function! envelop#LinkBins()

  " get targets to link
  let l:targets_to_link = []
  for [name, settings] in items(g:envelop_envs)
    if has_key(settings, 'add_to_path')
      for target in settings['add_to_path']
        let l:target_path = s:get_venv_path(name) . '/' . target
        if filereadable(l:target_path)
          let l:targets_to_link += [l:target_path]
        endif
      endfor
    endif
  endfor

  " create bin path if needed
  let s:envelop_bin_path = g:envelop_path . '/bin'
  if !isdirectory(s:envelop_bin_path) && !empty(l:targets_to_link)
    call mkdir(s:envelop_bin_path, 'p')
  endif

  " link the targets into the bin path
  for target in l:targets_to_link
    if !exists(s:envelop_bin_path . split(target, '/')[-1])
      call system([
        \ 'ln', '-s', target, s:envelop_bin_path
        \ ])
    endif
  endfor

  " add the bin path to $PATH
  let $PATH .= ':' . s:envelop_bin_path

endfunction


function! envelop#UnlinkBins()
  let s:envelop_bin_path = g:envelop_path . '/bin'
  call delete(s:envelop_bin_path, 'rf')
endfunction


function! envelop#RelinkBins()
  call envelop#UnlinkBins()
  call envelop#LinkBins()
endfunction
