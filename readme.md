# Neovenv

## About

envelop is a [Neovim](https://github.com/neovim/neovim) plugin for managing virtual environments.

## Compatibility

At the moment, envelop is only compatible with Neovim.

## Install

Using [**vim-plug**](https://github.com/junegunn/vim-plug):

`Plug 'timbedard/envelop'`

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
    \ 'add_to_path': ['bin/python3', 'bin/pip3'],
    \ 'commands': {
      \ 'create': ['python3', '-m', 'venv', '.'],
      \ 'install': ['{vpath}bin/pip', 'install'],
      \ 'update': ['{vpath}bin/pip', 'install', '--upgrade'],
      \ },
    \ 'host_prog_target': 'bin/python',
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
|`g:envelop_add_to_path`|`1`|whether to add binaries to path|

## Commands

### Virtual Environment Management

- `EnvelopCreate` Create all environments.
- `EnvelopUpdate`  Update packages in environments.
- `EnvelopDestroy` Destroy all environments (and binary links).

### $PATH Management

- `EnvelopLink` Link environment binaries.
- `EnvelopUnlink` Unlink environment binaries.
- `EnvelopRelink` Unlink environment binaries and create fresh links.
