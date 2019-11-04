# Description
Plugin to make VIM an IDE.

# Features
* Text search in multiple files (based on ag)
  * Support literal or regex base pattern
  * Support user specified file types
  * Case-sensitive and whole-word option configurable
* cscope wrapper
  * Find symbol by name
  * Find callers
  * Find callees
* Call-tree generator
  * Generate caller tree
  * Generate callee tree
* Search history
  * All search history is preserved and displayed in a seperate buffer
  * Last browsed position of each search is preserved that helps to navigate between multiple search results

# Default Keymaps
Note the default Leader key is '\'

| Keymap      |  Comand            |  Description
|-------------|--------------------|------------------------------------|
| \<Leader\>s |  :Isymb<CR>        | Find symbol with                   |
| \<Leader\>d |  :Idefi<CR>        | Find global definition             |
| \<Leader\>c |  :Icall<CR>        | Find callees                       |
| \<Leader\>b |  :Icaby<CR>        | Find callers                       |
| \<Leader\>f |  :Ifile<CR>        | Find files by name                 |
| \<Leader\>i |  :Iincl<CR>        | Find include files                 |
| \<Leader\>l |  :Ilast<CR>        | Find with last grep options        |
| \<Leader\>g |  :Igrep<CR>        | Find with grep (ag)                |
| \<Leader\>r |  :Icallertree<CR>  | Draw caller tree of current symbol |
| \<Leader\>e |  :Icalleetree<CR>  | Draw callee tree of current symbol |

# Installation
* This plugin can be downloaded from [https://github.com/tristar2001/vim-cide](https://github.com/tristar2001/vim-cide)
* ag can be downloaded from [https://github.com/ggreer/the_silver_searcher](https://github.com/ggreer/the_silver_searcher)
* cscope can be downloaded from [http://cscope.sourceforge.net/](http://cscope.sourceforge.net/)

# Configuration
* The following global variables can be configured from .vimrc or \_vimrc 
Note this step is optional. And it's needed only if a customization is needed

```vim
" C-IDE configuration
let g:cide_shell_cscope   = 'cscope'
let g:cide_shell_ag       = 'ag'
let g:cide_shell_find     = 'C:/Program Files/Git/usr/bin/find.exe'
let g:cide_shell_date     = 'date /T'
let g:cide_grep_filespecs = ['-G "Makefile|\.(c|cpp|h|hpp|cc|mk|mak)$"', "--cpp", "-cc", "--matlab", "--vim", "-a"]
```
# Screenshots
![main](https://github.com/tristar2001/images/blob/master/vim-cide/main.png)

