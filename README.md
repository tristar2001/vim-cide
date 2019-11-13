# Description
Powerful searching and navigation plugin that makes VIM an IDE (based on ag and cscope).

# Features
* Text search in multiple files (based on silver-searcher ag)
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
  * The history of all search requests (cscope or ag) is preserved and displayed in QHistory buffer
  * The last browsed position (selected item in the QResult window) of each search is preserved; it makes the navigation between multiple search results much easier
  
# Highlights
Traditional grep-like search is one dimensional, and the subsequent grep results overwrites the previous one. This plugin essentially implements a two-level navigation tree
* The first level is the history of past search requests displayed in the QHistory window (as shown in the screenshot), in which the user can easily trace back what keywords/symbols have been searched earlier
* The second level is the traditional grep/cscope results displayed in the QResult window, where the user can navigate among the results of a particular search
* The user can easily navigate across the two levels

This approach is especially useful for studying and navigation inside a large or unfamiliar code base.

# Example work flow
* Start a search with option configuration
  * \<Leader\>g to search a symbol with ag (silver searcher), configure file types, base directory, and other options (case, whole-word, etc.)
  * \<Leader\>s to search a symbol with cscope
* Search with last configured options
  * \<Leader\>l
* Navigate between search results inside the `QResult' window
  * Double-click items in "QResulst" (search result) window to view the corresponding code
* Navigate between history search requests
  * Double-click items in "QHistory" (Search History) window for previous search results

# Default Keymaps
Note the default <Leader> key is '\\'

| Keymap      |  Comand            |  Description
|-------------|--------------------|------------------------------------|
| \<Leader\>s |  :Isymb\<CR\>        | Find symbol with                   |
| \<Leader\>d |  :Idefi\<CR\>        | Find global definition             |
| \<Leader\>c |  :Icall\<CR\>        | Find callees                       |
| \<Leader\>b |  :Icaby\<CR\>        | Find callers                       |
| \<Leader\>f |  :Ifile\<CR\>        | Find files by name                 |
| \<Leader\>i |  :Iincl\<CR\>        | Find include files                 |
| \<Leader\>l |  :Ilast\<CR\>        | Find with last grep options        |
| \<Leader\>g |  :Igrep\<CR\>        | Find with grep (ag)                |
| \<Leader\>r |  :Icallertree\<CR\>  | Draw caller tree of current symbol |
| \<Leader\>e |  :Icalleetree\<CR\>  | Draw callee tree of current symbol |

# Installation
* Dependencies
  * silver searcher (ag): can be downloaded from [https://github.com/ggreer/the_silver_searcher](https://github.com/ggreer/the_silver_searcher)
  * cscope: can be downloaded from [http://cscope.sourceforge.net/](http://cscope.sourceforge.net/)
  * find: the windows version can be found under C:/Program Files/Git/usr/bin/find.exe if Git was installed
* Manual installation
  * Download this plugin from [https://github.com/tristar2001/vim-cide](https://github.com/tristar2001/vim-cide)
  * Copy downloaded cide.vim to vimfiles/plugin/ folder
* Vundle installation
  * Prerequisite: install Vundle from [https://github.com/VundleVim/Vundle.vim](https://github.com/VundleVim/Vundle.vim)
  * Insert the following line in .vimrc (or \_vimrc), after "Plugin 'VundleVim/Vundle.vim'", and before "call vundle#end()"
    ```vim
    Plugin 'tristar2001/vim-cide'
    ```
  * Execute :PluginInstall

# Configuration
* The following global variables can be configured from .vimrc or \_vimrc .

Note this step is **optional**. And it's usually needed when any of the following commands (like find.exe) is not present in any searchable path.

```vim
" C-IDE configuration
let g:cide_shell_cscope   = 'cscope'
let g:cide_shell_ag       = 'ag'
let g:cide_shell_find     = 'C:/Program Files/Git/usr/bin/find.exe'
let g:cide_shell_date     = 'date /T'
let g:cide_grep_filespecs = ['-G "Makefile|\.(c|cpp|h|hpp|cc|mk|mak)$"', "--cpp", "-cc", "--matlab", "--vim", "-a", '-G "\.(Po)$" --hidden', '-G "\.(d)$" --hidden'])
```
# Screenshots
![main](https://github.com/tristar2001/images/blob/master/vim-cide/main.png)

