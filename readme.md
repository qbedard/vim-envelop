# envelop

## About

**envelop** is a [Neovim](https://github.com/neovim/neovim) plugin for managing virtual environments.

## Compatibility

At the moment, envelop is only compatible with Neovim.

## Install

Using [**vim-plug**](https://github.com/junegunn/vim-plug):

`Plug 'timbedard/vim-envelop'`

## Options

### Example Venv Configuration

```vim
let g:envelop_envs = {
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
  \ 'python3': {
    \ 'commands': {
      \ 'create': ['python3', '-m', 'venv', '.'],
      \ 'install': ['{vpath}bin/pip', 'install'],
      \ 'update': ['{vpath}bin/pip', 'install', '--upgrade'],
      \ },
    \ 'host_prog_target': 'bin/python',
    \ 'link': ['bin/python3', 'bin/pip3'],
    \ 'packages': [
      \ 'pip',
      \ 'pynvim',
      \ ],
    \ },

  \ }
```

|Name|Default|Description|
|-|-|-|
|`g:envelop_path`|`$XDG_DATA_HOME/venv`|where venvs are stored|
|`g:envelop_envs_enabled`|`['node', 'python3']`|which venvs to enable|
|`g:envelop_link`|`1`|whether to add binaries to path|

## Commands

### Virtual Environment Management

- `EnvCreate` Create all environments.
- `EnvUpdate`  Update packages in environments.
- `EnvDestroy` Destroy all environments (and binary links).

### $PATH Management

- `EnvLink` Link environment binaries.
- `EnvUnlink` Unlink environment binaries.
- `EnvRelink` Unlink environment binaries and create fresh links.
