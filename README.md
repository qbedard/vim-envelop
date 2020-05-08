# envelop ![Tests](https://github.com/timbedard/vim-envelop/workflows/Test/badge.svg)

## About

**envelop** is a [Neovim](https://github.com/neovim/neovim) plugin for managing virtual environments.

## Compatibility

At the moment, envelop is only compatible with Neovim.

## Install

Using [**vim-plug**](https://github.com/junegunn/vim-plug):

`Plug 'timbedard/vim-envelop'`

## Commands

### Virtual Environment Management

- `EnvCreate` Create all environments (including package installation and linking).
- `EnvInstall` Install packagess for all environments.
- `EnvUpdate`  Update packages in environments.
- `EnvDestroy` Destroy all environments (and binary links).

### $PATH Management

- `EnvLink` Link environment binaries.
- `EnvUnlink` Unlink environment binaries.
- `EnvRelink` Unlink environment binaries and create fresh links.

## Options

|Name|Default|Description|
|-|-|-|
|`g:envelop_path`|`$XDG_DATA_HOME/venv`|where venvs are stored|
|`g:envelop_envs_enabled`|`['node', 'python3']`|which venvs to enable|
|`g:envelop_link`|`1`|whether to add binaries to path|

### Built-in Environments

#### Node

|Name|Default|Description|
|-|-|-|
|`g:envelop_node_link`|`[]`|files/dirs to link into $PATH|
|`g:envelop_node_packages`|`['neovim']`|packages to install/update|
|`g:envelop_node_set_host_prog`|`1`|whether to set `node_host_prog`|

#### Python

|Name|Default|Description|
|-|-|-|
|`g:envelop_python_link`|`['bin/pip', 'bin/python']`|files/dirs to link into $PATH|
|`g:envelop_python_packages`|`['pip', 'pynvim']`|packages to install/update|
|`g:envelop_python_set_host_prog`|`1`|whether to set `python_host_prog`|

#### Python3

|Name|Default|Description|
|-|-|-|
|`g:envelop_python3_link`|`['bin/pip3', 'bin/python3']`|files/dirs to link into $PATH|
|`g:envelop_python3_packages`|`['pip', 'pynvim']`|packages to install/update|
|`g:envelop_python3_set_host_prog`|`1`|whether to set `python3_host_prog`|
