" neovenv/plugin/neovenv.vim
"-----------------------------------------------------------------------------"
"    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    "
"                                   Neovenv                                   "
"    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    "
"-----------------------------------------------------------------------------"

" if exists('g:loaded_neovenv')
"   finish
" endif
" let g:loaded_neovenv = 1

"----------------------------------- Setup ------------------------------------"
" get/set globals
let g:neovenv_dir_name = get(g:, 'neovenv_dir_name', 'venv')
let g:neovenv_path = get(g:, 'neovenv_path', stdpath('data') . '/' . g:neovenv_dir_name)
let g:neovenv_enabled = get(g:, 'neovenv_enabled', [
  \ 'node', 'python3',
  \ ])
let g:neovenvs = get(g:, 'neovenvs', neovenv#GetDefaultNeovenvs())
let g:neovenv_add_to_path = get(g:, 'neovenv_add_to_path', 1)

" create venv dir if needed
if !empty(g:neovenvs)
  \ && !empty(g:neovenv_enabled)
  \ && !isdirectory(g:neovenv_path)
  call mkdir(g:neovenv_path, 'p')
endif

" set Neovim's '_host_program' globals
call neovenv#SetHostProgGlobals()

" add neovenv bins to path
if g:neovenv_add_to_path && executable('ln')
  call neovenv#LinkBins()
endif

"---------------------------------- Commands ----------------------------------"
" venv commands
command! CreateVenvs call neovenv#CreateVenvs()
command! UpdateVenvs call neovenv#UpdateVenvs()
command! DestroyVenvs call delete(g:neovenv_path, 'rf')

" path commands
command! LinkBins call neovenv#LinkBins()
command! RelinkBins call neovenv#RelinkBins()
command! UnlinkVins call neovenv#UnlinkBins()
