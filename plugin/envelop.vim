" envelop/plugin/envelop.vim
"-----------------------------------------------------------------------------"
"    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    "
"                                 vim-envelop                                 "
"    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    "
"-----------------------------------------------------------------------------"

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
let g:envelop_add_to_path = get(g:, 'envelop_add_to_path', 1)
let g:envelop_envs_enabled = get(g:, 'envelop_envs_enabled', ['node', 'python3'])
let g:envelop_envs = get(g:, 'envelop_envs', envelop#GetDefaultEnvs())

" create env dir if needed
if !empty(g:envelop_envs)
  \ && !empty(g:envelop_envs_enabled)
  \ && !isdirectory(g:envelop_path)
  call mkdir(g:envelop_path, 'p')
endif

" set Neovim's '_host_program' globals
call envelop#SetHostProgGlobals()

" add envelop bins to path
if g:envelop_add_to_path
  call envelop#addBinsToPath()
endif

"---------------------------------- Commands ----------------------------------"
" env commands
command! EnvelopCreate call envelop#CreateEnvs()
command! EnvelopUpdate call envelop#UpdateEnvs()
command! EnvelopDestroy call envelop#DestroyEnvs()

" path commands
command! EnvelopLink call envelop#LinkBins()
command! EnvelopUnlink call envelop#UnlinkBins()
command! EnvelopRelink call envelop#RelinkBins()
