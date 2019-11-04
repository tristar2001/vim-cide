# Description
Plugin to make VIM an IDE.

# Features
* Text search in files (based on ag): support literal or regex base pattern;
* cscope (

# Installation
* This plugin can be downloaded from [https://github.com/tristar2001/vim-cide](https://github.com/tristar2001/vim-cide)
* ag can be downloaded from [https://github.com/ggreer/the_silver_searcher](https://github.com/ggreer/the_silver_searcher)
* cscope can be downloaded from [http://cscope.sourceforge.net/](http://cscope.sourceforge.net/)

# Configuration
* The following global variables can be configured from .vimrc or \_vimrc 

```vim
" C-IDE configuration
let g:cide_shell_cscope   = 'cscope'
let g:cide_shell_ag       = 'ag'
let g:cide_shell_find     = 'find'
let g:cide_shell_date     = 'date /T'
let g:cide_grep_filespecs = ['-G "Makefile|\.(c|cpp|h|hpp|cc|mk|mak)$"', "--cpp", "-cc", "--matlab", "--vim", "-a"]
```

# Screenshots
TBD

