# Table of Content

<!-- vim-markdown-toc GFM -->

* [Description](#description)
* [Features](#features)
* [Highlights](#highlights)
* [Example work flow](#example-work-flow)
* [Default Keymaps](#default-keymaps)
    * [Global hotkeys](#global-hotkeys)
    * [Hotkeys in the "Find Window"](#hotkeys-in-the-find-window)
* [Installation](#installation)
    * [Dependencies](#dependencies)
    * [Manual installation](#manual-installation)
    * [Vundle installation](#vundle-installation)
* [Configuration](#configuration)
* [Screenshots](#screenshots)

<!-- vim-markdown-toc -->

# Description

Powerful searching and navigation plugin that makes VIM an IDE based on
GNU find, ripgrep( _rg_ ), and _cscope_.

# Features

* Text search in multiple files based on _rg_

  * Support literal or regex based patterns

  * Support user specified file types

  * Configurable search options (case-sensitive, whole-word, regex, recursive)

* cscope wrapper

  * Find all references to a symbol

  * Find all callers of a symbol (function only)

  * Find all callees of a symbol (function only)

* Call-tree generator

  * Caller tree of a symbol

  * Callee tree of a symbol

* Search history

  * The history of all search requests (cscope or rg) is preserved and
  displayed in QHistory buffer

  * The last browsed position (selected item in the QResult window) of each
  search is preserved; it makes the navigation between multiple search results
  much easier
 
* Integrated find utility

  * Integrated GNU find utility and preview; sort by modified time, file size,
  file names, and containing folders; open by associated programs

# Highlights

Traditional grep-like search is one dimensional, and the subsequent grep
results overwrites the previous one. This plugin essentially implements a
two-level navigation tree

* The first level is the history of past search requests displayed in the
  QHistory window (as shown in the screenshot), in which the user can easily
  trace back what keywords/symbols have been searched earlier

* The second level is the traditional grep/cscope results displayed in the
  QResult window, where the user can navigate among the results of a particular
  search

* The user can easily navigate across the two levels

This approach is especially useful for studying and navigation inside a large
or unfamiliar code base.

# Example work flow

* Start a search with option configuration

  * \<Leader\>g to search a symbol with _rg_, configure file types, base
  directory, and other options (case, whole-word, etc.)

  * \<Leader\>s to search a symbol with cscope

* Search with last configured options

  * \<Leader\>l

* Navigate between search results inside the 'QResult' window

  * Double-click items in "QResulst" (search result) window to view the
  corresponding code

* Navigate between history search requests

  * Double-click items in "QHistory" (Search History) window for previous
  search results

# Default Keymaps

## Global hotkeys

Note the default <Leader> key is '\\'

| Keymap      |  Command             |  Description                       |
|-------------|----------------------|------------------------------------|
| \<Leader\>s |  :Isymb\<CR\>        | Find symbol with                   |
| \<Leader\>d |  :Idefi\<CR\>        | Find global definition             |
| \<Leader\>c |  :Icall\<CR\>        | Find callees                       |
| \<Leader\>b |  :Icaby\<CR\>        | Find callers                       |
| \<Leader\>f |  :Ifile\<CR\>        | Find files by name                 |
| \<Leader\>i |  :Iincl\<CR\>        | Find include files                 |
| \<Leader\>l |  :Ilast\<CR\>        | Find with last grep options        |
| \<Leader\>g |  :Igrep\<CR\>        | Find with grep ( _rg_ )            |
| \<Leader\>r |  :Icallertree\<CR\>  | Draw caller tree of current symbol |
| \<Leader\>e |  :Icalleetree\<CR\>  | Draw callee tree of current symbol |

## Hotkeys in the "Find Window"

| Keymap                | Description                               |
|-----------------------|-------------------------------------------|
| ?                     | help message                              |
| \<Double-Click\>      | Preview                                   |
| v                     | Preview and move to the next file         |
| v                     | Preview and move to the previous file     |
| g                     | View in gvim                              |
| x                     | Open file with associated program         |
| \<Ctrl-Right\>        | Increase column width for file name field |
| \<Ctrl-Left\>         | Decrease column width for file name field |
| \<Leader\>\<Leader\>t | Sort by file time   in decreased order    |
| \<Leader\>\<Leader\>T | Sort by file time   in increased order    |
| \<Leader\>\<Leader\>s | Sort by file size   in decreased order    |
| \<Leader\>\<Leader\>S | Sort by file size   in increased order    |
| \<Leader\>\<Leader\>n | Sort by file name   in decreased order    |
| \<Leader\>\<Leader\>N | Sort by file name   in increased order    |
| \<Leader\>\<Leader\>f | Sort by folder name in decreased order    |
| \<Leader\>\<Leader\>F | Sort by folder name in increased order    |

<!--
  * silver searcher (ag): can be downloaded from [https://github.com/ggreer/the\_silver\_searcher](https://github.com/ggreer/the\_silver\_searcher)
-->

# Installation
## Dependencies

  * ripgrep ( _rg_ ) recommended: can be downloaded from [https://github.com/BurntSushi/ripgrep/releases](https://github.com/BurntSushi/ripgrep/releases)

  * cscope: can be downloaded from [http://cscope.sourceforge.net/](http://cscope.sourceforge.net/)

  * find: the windows version can be found under C:/Program Files/Git/usr/bin/find.exe if Git was installed

## Manual installation

  * Download this plugin from [https://github.com/tristar2001/vim-cide](https://github.com/tristar2001/vim-cide)

  * Copy downloaded cide.vim to vimfiles/plugin/ folder

## Vundle installation

  * Prerequisite: install Vundle from [https://github.com/VundleVim/Vundle.vim](https://github.com/VundleVim/Vundle.vim)

  * Insert the following line in .vimrc (or \_vimrc), after "Plugin 'VundleVim/Vundle.vim'", and before "call vundle#end()"

    ```vim
    Plugin 'tristar2001/vim-cide'
    ```
  * Execute :PluginInstall

# Configuration

* The following global variables can be configured from .vimrc or \_vimrc .

Note this step is **optional**. And it's usually needed when any of the
following commands (like find.exe) is not present in any searchable path.

```vim
" C-IDE configuration
if has("win32")
    let g:cide_shell_find     = 'C:/Program Files/Git/usr/bin/find.exe'
    let g:cide_shell_sort     = 'C:/Program Files/Git/usr/bin/sort.exe'
    let g:cide_shell_date     = 'date /T'
else
    " let g:cide_shell_find   = 'find'
    " let g:cide_shell_sort   = 'sort'
    " let g:cide_shell_date   = 'date +\"%a %D %T.%3N\"'
endif
let g:cide_shell_cscope       = 'cscope'
let g:cide_shell_grep         = 'rg'
let g:cide_grep_filespecs     = ["-tcxx", "-tcpp", "-tc", "-tvim", "-tmatlab", '-g "*"']
```
# Screenshots

![main](https://github.com/tristar2001/images/blob/master/vim-cide/main.png)

![main](https://github.com/tristar2001/images/blob/master/vim-cide/findwin.png)

