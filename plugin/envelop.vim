" envelop/plugin/envelop.vim
"------------------------------------------------------------------------------"
"    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    "
"                                 vim-envelop                                  "
"    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    "
"------------------------------------------------------------------------------"

if exists('g:loaded_envelop')
  finish
endif
let g:loaded_envelop = 1

"----------------------------------- Setup ------------------------------------"
" get/set globals
let g:envelop_dir_name = get(g:, 'envelop_dir_name', 'venv')
let g:envelop_path = get(
  \ g:, 'envelop_path', stdpath('data') . '/' . g:envelop_dir_name
  \ )
let g:envelop_envs_enabled = get(g:, 'envelop_envs_enabled', ['node', 'python3'])
let g:envelop_envs = get(g:, 'envelop_envs', envelop#GetDefaultEnvs())

let g:envelop_link = get(g:, 'envelop_link', 1)
let g:envelop_set_host_prog = get(g:, 'envelop_set_host_prog', 1)

" create env dir if needed
if !empty(g:envelop_envs)
  \ && !empty(g:envelop_envs_enabled)
  \ && !isdirectory(g:envelop_path)
  call mkdir(g:envelop_path, 'p')
endif

" set Neovim's '_host_program' globals
if g:envelop_set_host_prog
  call envelop#SetHostProgGlobals()
endif

" add envelop links to path
if g:envelop_link
  call envelop#AddLinksToPath()
endif

"---------------------------------- Commands ----------------------------------"
" env commands
command! EnvCreate call envelop#CreateEnvs()
command! EnvUpdate call envelop#UpdateEnvs()
command! EnvDestroy call envelop#DestroyEnvs()

" path commands
command! EnvLink call envelop#Link()
command! EnvUnlink call envelop#Unlink()
command! EnvRelink call envelop#Relink()
