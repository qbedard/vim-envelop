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
call envelop#Set('dir_name', 'venv')
call envelop#Set('path', stdpath('data') . '/' . g:envelop_dir_name)

call envelop#Set('enabled', ['node', 'python3'])
call envelop#Set('envs', {})
call envelop#Set('link', 1)
call envelop#Set('set_host_prog', 1)

" create env dir if needed
if !empty(g:envelop_envs)
  \ && !empty(g:envelop_enabled)
  \ && !isdirectory(g:envelop_path)
  call envelop#CreateEnvelopDir()
endif

" load env definitions
for name in g:envelop_enabled
  call envelop#LoadEnv(name)
endfor

" add envelop links to path
if g:envelop_link
  call envelop#AddLinksToPath()
endif


"---------------------------------- Commands ----------------------------------"
" env commands
command! EnvCreate call envelop#CreateEnvs()
command! EnvInstall call envelop#InstallEnvPackages()
command! EnvUpdate call envelop#UpdateEnvs()
command! EnvDestroy call envelop#DestroyEnvs()

" path commands
command! EnvLink call envelop#Link()
command! EnvUnlink call envelop#Unlink()
command! EnvRelink call envelop#Relink()
