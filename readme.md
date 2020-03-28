# Neovenv

## About

Neovenv is a Neovim plugin for managing virtual environments.

## Install

Using [**vim-plug**](https://github.com/junegunn/vim-plug):

`Plug 'timbedard/neovenv'`

## Options

### Example Venv Configuration

```vim
let g:neovenvs = {
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
|`g:neovenv_path`|`$XDG_DATA_HOME/venv`|where venvs are stored|
|`g:neovenvs_enabled`|`['node', 'python3']`|which venvs to enable|
|`g:neovenv_add_to_path`|`1`|whether to add binaries to path|

## Commands

### Virtual Environment Management

- `CreateVenvs` creates all environments.
- `UpdateVenvs`  updates packages in environments.
- `DestroyVenvs` destroys all environments (and binary links).

### $PATH Management

- `LinkBins` links environment binaries.
- `UnlinkVins` unlinks environment binaries.
- `RelinkBins` unlinks environment binaries and creates fresh links.
