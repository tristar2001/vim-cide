" Description:      C-IDE vim plugin
" Version:          0.8
" Last Modified:    11/12/2019
"
" MIT License
" 
" Copyright (c) 2005-2019 Jun Huang (tristar2001)
" 
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
" 
" The above copyright notice and this permission notice shall be included in all
" copies or substantial portions of the Software.
" 
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
" SOFTWARE.

" Load once
if exists("g:cide_loaded")
    finish
endif
let g:cide_loaded = 1
set shellslash

function! s:MsgInfo(msg)
    call confirm('[C-IDE-INFO] '.a:msg.' ')
endfunction

function! s:MsgError(msg)
    call confirm('[C-IDE-ERROR] '.a:msg.' ')
endfunction

function! s:InitVarGlobal(var_name, var_default)
    if exists('g:'.a:var_name)
        let s:{a:var_name} = g:{a:var_name}
    else
        let s:{a:var_name} = a:var_default
    end
endfunction

function! s:ChangeDirectory(folder)
    let oldpath = getcwd()
    exec "lcd ".a:folder
    return oldpath
endfunction

function! s:InitVars()
    " Initialize global configurable variable default
    if has('win32')
        let default_cide_shell_find = ''
        " Make sure windows/system32/find.exe is not used
        for cmd in split(system('where find.exe'), '\n')
            let syscmd = '\System32\find.exe'
            let syslen = strlen(syscmd)
            let cmdlen = strlen(cmd)
            if (cmdlen > strlen(syscmd))
                if (tolower(syscmd) != tolower(strpart(cmd, cmdlen - syslen, syslen)))
                    let default_cide_shell_find = substitute(cmd, '\\', '\\\\', 'g')
                    break
                endif
            end
        endfor
        let default_cide_shell_date     = 'date /T'
    else
        let default_cide_shell_find     = 'find'
        let default_cide_shell_date     = 'date +\"%a %D %T.%3N\"'
    endif

    " Initialize global configurable variables only when it's not defined
    call s:InitVarGlobal('cide_shell_cscope',   'cscope')
    call s:InitVarGlobal('cide_shell_ag',       'ag')
    call s:InitVarGlobal('cide_shell_find',     default_cide_shell_find)
    call s:InitVarGlobal('cide_shell_date',     default_cide_shell_date)
    call s:InitVarGlobal('cide_grep_filespecs', ['-G "Makefile|\.(c|cpp|h|hpp|cc|mk)$"', "--cpp", "-cc", "--matlab", "--vim", "-a", '-G "\.(Po)$" --hidden', '-G "\.(d)$" --hidden'])

    let s:cpo_save = &cpo
    set cpo&vim

    " Constant strings
    let s:CIDE_CFG_FNAME                = '_cide.cfg'
    let s:CSCOPE_OUT_FNAME              = 'cscope.out'
    let s:CIDE_WIN_TITLE_QUERYLIST      = "QHistory"
    let s:CIDE_WIN_TITLE_QUERYRES       = "QResult"
    let s:CIDE_WIN_TITLE_CALLEETREE     = "Callees"
    let s:CIDE_WIN_TITLE_CALLERTREE     = "Callers"
    let s:CIDE_WIN_TITLE_GREPOPTIONS    = "Options"
    let s:CIDE_WIN_TITLE_SHELL_OUT      = "ShellOutput"
    let s:CIDE_WIN_CODE_MARK            = "CODEWINDOW"
    let s:CIDE_RES_IND_MARK             = "<=="
    let s:CIDE_SHELL_QUOTE_CHAR         = '"' " Character to use to quote patterns and filenames before passing to grep.

    " Load default grep options
    let s:cide_cur_cfg_path             = ""
    let s:grep_opt_dir                  = getcwd()
    let s:grep_opt_whole                = 0
    let s:grep_opt_icase                = 1
    let s:grep_opt_recurse              = 1
    let s:grep_opt_regex                = 0
    let s:grep_opt_files                = s:cide_grep_filespecs[0]
    
    " Initialize default runtime variables
    let s:cide_cur_query_type           = 'grep'
    let s:cide_cur_query_count          = 0
    let s:cide_cur_sel_query            = 0
    let s:cide_cur_cscope_out_dir       = ""
    let s:cide_flag_cscope_case         = 0
    let s:cide_flag_unique_names        = 1

    " Mark code window
    let w:window_cidemark           = s:CIDE_WIN_CODE_MARK
endfunction

" Initialize global variables
call s:InitVars()

function! s:GetCmdName(cmdn)
    if (a:cmdn == '0')
        let cmd = "symb"
    elseif (a:cmdn == '1') 
        let cmd = "defi"
    elseif (a:cmdn == '2') 
        let cmd = "caby"
    elseif (a:cmdn == '3') 
        let cmd = "call"
    elseif (a:cmdn == '4') 
        let cmd = "text"
    elseif (a:cmdn == '5') 
        let cmd = "????"
    elseif (a:cmdn == '6') 
        let cmd = "grep"
    elseif (a:cmdn == '7') 
        let cmd = "file"
    elseif (a:cmdn == '8') 
        let cmd = "incl"
    else
        let cmd = "_"
    endif
    return cmd
endfunction

function! s:GetCmdPrompt(cmdn)
    if (a:cmdn == '0')
        let cmd = "symbol: "
    elseif (a:cmdn == '1') 
        let cmd = "definition of: "
    elseif (a:cmdn == '2') 
        let cmd = "functions called by: "
    elseif (a:cmdn == '3') 
        let cmd = "functions who calls: "
    elseif (a:cmdn == '4') 
        let cmd = "text: "
    elseif (a:cmdn == '5') 
        let cmd = "text: "
    elseif (a:cmdn == '6') 
        let cmd = "egrep: "
    elseif (a:cmdn == '7') 
        let cmd = "file: "
    elseif (a:cmdn == '8') 
        let cmd = "include :"
    else
        let cmd = "_"
    endif
    return cmd
endfunction

function! s:SaveStrToFile(str, fname)
    "force redraw to clear postponed echo
    redraw 
    let old_verbose = &verbose
    set verbose&vim
    exe "redir! > " . a:fname
    silent echon a:str
    redir END
    let &verbose = old_verbose
endfunction

function! s:ExecVimCmdOutput(cmd)
    redraw 
    let old_verbose = &verbose
    set verbose&vim
    exec "redir @z"
    exec a:cmd
    "silent echon a:str
    redir END
    let &verbose = old_verbose
endfunction

function! s:RebuildCscopeSub()
    let curpath0 = expand("%:p:h")
    let curpath0 = input("Build cscope.out under: ", curpath0)
    if curpath0 == ""
        echohl WarningMsg | echomsg "Build canceled"  | echohl None
        let s:cide_cur_cscope_out_dir = ""
        call s:MsgInfo("CheckCscopeConnection(): build was canceled")
        return 0
    endif
    let oldpath = s:ChangeDirectory(curpath0)
    let cscope_files = curpath0 . "/cscope.files"
    let cmd = '"'.s:cide_shell_find . "\" . -regex \"[^ ]*\\.\\(c\\|cc\\|cpp\\|h\\)\""
    let cmd = input("Generating " . cscope_files . ': ' , cmd)
    let cmd_out = system(cmd)
    call s:SaveStrToFile(cmd_out, cscope_files) 
    let cmd_out = system(s:cide_shell_cscope. " -b -R -u")
    call s:ChangeDirectory(oldpath)
    let s:cide_cur_cscope_out_dir = curpath0
    return 1
endfunction

function! s:FindFileInParentFolders(fname)
    let curpath = expand("%:p:h")
    while strlen(curpath) > 3
        if filereadable(curpath . "/" . a:fname)
            break
        endif
        let curpath = fnamemodify(curpath, ":h")
    endwhile
    return curpath
endfunction

function! s:CheckCscopeConnection()
    if (strlen(s:cide_cur_cscope_out_dir) > 0)
        return 1
    endif
    let curpath = s:FindFileInParentFolders(s:CSCOPE_OUT_FNAME)
    if strlen(curpath) <= 3
        echohl WarningMsg | echomsg "Error: ".s:CSCOPE_OUT_FNAME." does not exist."  | echohl None
        return s:RebuildCscopeSub()
    else
        let s:cide_cur_cscope_out_dir = curpath
        return 1
    endif
endfunction

function! s:GotoWindow(wnum)
    if (a:wnum<0)
        return
    endif
    exec a:wnum . "wincmd w"
endfunction

function! s:CloseWindow(wnum)
    if (a:wnum<0)
        return
    endif
    exec a:wnum . "wincmd w"
    "    :q!
    close
endfunction

function! s:CloseWindowByName(bufname)
    let wnum = s:FindWindow(a:bufname)
    if (wnum != -1)
        exec wnum . "wincmd w"
        :q!
    endif
    return wnum
endfunction

function! s:GotoWindowByName(bufname)
    let wnum = s:FindWindow(a:bufname)
    if (wnum != -1)
        exec wnum . "wincmd w"
    endif
    return wnum
endfunction

" Adds content to the query result window.
function! s:PopulateQueryResult(qidx)
    let qres_win = s:FindWindow(s:CIDE_WIN_TITLE_QUERYRES)
    if (qres_win == -1)
        call s:MsgError("failed to find QueryResult windows")
        return 0
    endif

    " Update current s:cide_cur_query_type
    let s:cide_cur_query_type = split(s:QueryCommand{a:qidx})[0]

    "goto query res window
    call s:GotoWindow(qres_win)

    " Set syntax
    call s:SetQueryResultWinSyntax()

    "delete all content
    setlocal modifiable
    exe '1,$delete'
    silent! exe "read ". s:QueryResultFile{a:qidx}
    1d
    if (v:version >= 700)
        " sort
    endif
    let nLines = line("$")
    let str = '===> '. s:QueryCommand{a:qidx}." ".s:QueryPattern{a:qidx} . " (" . nLines . " in total)"
    let str = str . ' under "' . s:QueryBaseDir{a:qidx} . '"'
    call append(0, str)
    " silent! exec "%s/\r//g"
    silent! exec ":%s/\r$//"
    silent! setlocal nomodifiable
    exec 1
    redraw
    let s:cide_cur_sel_query = a:qidx
    call s:MarkLine(s:QueryCurIdx{a:qidx}+1)
    redraw
    return nLines
endfunction

function! s:GetCscopeResult(cmd_num, pat, bCheckCase) " external
    if (a:cmd_num == "?" && a:cmd_num!=0)
        call s:MsgError("GetCscopeResult(): invalid cmd_num=".a:cmd_num)
        return
    endif

    if a:pat == ""
        let cmdprompt = s:GetCmdPrompt(a:cmd_num)
        let pattern = input("Find ".cmdprompt, expand("<cword>"))
        if pattern == ""
            return 0
        endif
        let s:cscope_pattern = pattern
    else
        let pattern = a:pat
        let s:cscope_pattern = a:pat
    endif

    if (s:CheckCscopeConnection()==0) 
        return 0
    endif

    let oldpath = s:ChangeDirectory(s:cide_cur_cscope_out_dir)
    let cscope_cmd = '"' . s:cide_shell_cscope . '" -R -L -'.a:cmd_num.' '.pattern
    let @z = system(cscope_cmd)
    let test = strpart(@z,1,5)
    call s:ChangeDirectory(oldpath)
    if(test=="Error")
        return 0
    endif

    "swap funcname and lineno fields
    let tstr0 = substitute("\n".@z, "\\n\\(\\S\\+\\)\\s\\+\\(\\S\\+\\)\\s\\+\\(\\d\\+\\)\\s\\+","\\n\\1 \\3 \\2 ","g")
    let s:cscope_cmd_out = strpart(tstr0,1) 
    if (strlen(s:cscope_cmd_out) < 3)
        echohl WarningMsg | 
                    \ echomsg "Error: Pattern " . pattern . " not found" | 
                    \ echohl None
        call s:MsgError("GetCscopeResult() processing failed")
        return 0
    endif
    return 1
endfunction "end of GetCscopeResult

function! s:GotoCodeWindow()
    let winnum = s:GetCodeWindow()
    if winnum == -1
        return
    endif
    call s:GotoWindow(winnum)    
endfunction

" Run the specified cscope command
function! s:RunCscope(cmd_num, patt)
    let retcode = s:GetCscopeResult(a:cmd_num, a:patt, 1)
    if (retcode==0)
        return
    endif
    let tmpfile = tempname()
    call s:SaveStrToFile(s:cscope_cmd_out, tmpfile)
    let pat = s:cscope_pattern

    if (s:cide_flag_cscope_case == 1)
        let casechar = "c"
    else
        let casechar = "n"
    endif

    let cmdname = s:GetCmdName(a:cmd_num)
    let cmdname = cmdname." ". casechar
    call s:InsertQuery(1, cmdname, pat, 0, tmpfile, s:cide_cur_cscope_out_dir)
    call s:GotoCodeWindow()
endfunction

function! s:FindWindow(bufName)
    " Try to find an existing window that contains our buffer.
    let bufNum = bufnr('^'.a:bufName.'$')
    if bufNum != -1
        let winNum = bufwinnr(bufNum)
    else
        let winNum = -1
    endif
    return winNum
endfunction

function! s:BuildQueryListItem(cmd, cnt, pat)
    let tstr = a:cnt
    let tstr = tstr . " "
    let tstr = tstr . a:cmd
    let tstr = tstr . " "
    let tstr = tstr . a:pat
    return tstr
endfunction 

" Must be called when both QueryList and QueryRes windows are open
function! s:RedrawQueryListQueryResult()
    let ii = 1
    let tstr = ""
    while (ii <= s:cide_cur_query_count)
        let tstr0 = s:BuildQueryListItem(s:QueryCommand{ii}, s:QueryNumFounds{ii}, s:QueryPattern{ii})
        let tstr = tstr . tstr0 . "\n"
        let ii = ii +1
    endwhile

    let winNumQL = s:GotoWindowByName(s:CIDE_WIN_TITLE_QUERYLIST)
    if winNumQL == -1
        call s:MsgError("QueryList window is not on focus")
        return
    endif

    setlocal modifiable
    let save_rep = &report
    let save_sc = &showcmd
    let &report = 10000
    set noshowcmd 

    " Delete all lines in buffer.
    1,$d _
    " Goto the end of the buffer put the buffer list and then delete the extra trailing blank line
    $
    put! = tstr
    $ d _
    exec 1
    call s:MarkLine(1)

    call s:PopulateQueryResult(1)

    let &report  = save_rep
    let &showcmd = save_sc
    setlocal nomodifiable
    set nobuflisted
endfunction

function! s:GetCodeWindow()
    let winnum = -1
    let i = 1
    while winbufnr(i) != -1
        if getwinvar(i, 'window_cidemark') == s:CIDE_WIN_CODE_MARK
            "	 let test = winbufnr(i)
            "	 echo "winbufnr=".test." title=".bufname(test)
            let winnum = i
            break
        endif
        let i = i + 1
    endwhile
    return winnum
endfunction

function! s:OpenViewFile(fname, lineno, basedir)
    if(a:fname=="")
        return
    endif
    let fname0=a:fname

    if (strpart(fname0,0,2)==".\\")
        let fname0 = strpart(fname0,2) 
    endif

    let basedir = a:basedir
    let slen = strlen(basedir)
    if(strpart(basedir,slen-1)=="/")
        let basedir = strpart(basedir, 0, slen-1)
    endif

    if (!(strpart(fname0, 1, 1) == ':' || strpart(fname0, 0, 1) == '/'))
        let fname0=basedir."/".fname0
        let fname0=fnamemodify(fname0,":.")
    endif

    echo fname0
    let winnum = s:GetCodeWindow()
    if winnum == -1
        "      echo "ACS window not found!"
        :top new
        let w:window_cidemark = s:CIDE_WIN_CODE_MARK
        let winnum = s:GetCodeWindow()
    endif
    call s:GotoWindow(winnum)

    let tmpbuf = bufnr('^'.fname0.'$')
    if (tmpbuf>0) "exists
        exec "b! ".tmpbuf
        "      echo "want ".fname0."(bufnr=".tmpbuf." now".bufname("%")
        if (&modified)
            let prtmsg = "File ".fname0." has been modified.\nDo you want to save it?"
            let retcode = confirm(prtmsg, "Leave Alone\nDiscard Change\nSave Change")
            if (retcode==1)
                silent! exec a:lineno
            elseif (retcode==2)
                silent! exec 'edit! ' . fname0
                silent! exec a:lineno
            elseif (retcode==3)
                exec "w"
                silent! exec a:lineno
            endif
        else
            "silent! exec 'edit! ' . fname0
            silent! exec a:lineno
        endif
    else
        let savebuf    = bufnr("%")
        "      echo "curbufname=".bufname("%")
        let savehidden = getbufvar(savebuf, "&bufhidden")
        call setbufvar(savebuf, "&bufhidden", "hide")

        silent! exec 'edit ' . fname0
        "exec 'edit ' . fname0
        let winnum = s:GetCodeWindow()
        call s:GotoWindow(winnum) "goto codewindow to prevent window change by taglist

        let tmpname = bufname("%")
        let tmpname = fnamemodify(tmpname,":p")
        let fname = fnamemodify(fname0,":p")
        if(tmpname==fname)
            silent! exec a:lineno
        else
            echo "edit failed: we want:".fname." now:".bufname("%")
        endif
        call setbufvar(savebuf, "&bufhidden", savehidden)
    endif
    set buflisted 
    "   :UMiniBufExplorer
endfunction

function! s:CB_ViewCurrentQueryResultItem()
    if (s:cide_cur_sel_query == 0 || s:cide_cur_sel_query>s:cide_cur_query_count)
        return
    endif
    if s:QueryNumFounds{s:cide_cur_sel_query} == 0
        return
    endif
    let idx = line('.')
    if (idx <= 1)
        return
    endif
    if (idx-1 >  s:QueryNumFounds{s:cide_cur_sel_query})
        return
    endif
    let s:QueryCurIdx{s:cide_cur_sel_query} = idx-1
    " find the window and select it
    let reswin = s:GotoWindowByName(s:CIDE_WIN_TITLE_QUERYRES)
    if (reswin == -1) 
        return
    endif

    call s:MarkLine(idx)

    " [open the file and] goto the line number
    let linestr = getline(idx)

    if s:cide_cur_query_type == 'grep'
        let idx_start = 0
        if (linestr[1] == ':' && (linestr[2] == '\\' || linestr[2] == '/'))
            let idx_start = 2
        endif
        let idx_colon1 = stridx(linestr, ":", idx_start)
        if (idx_colon1 < 1)
            call s:MsgError("incorrect format2")
            return
        endif
        let fname = strpart(linestr, idx_start, idx_colon1 - idx_start)
        let idx_colon2 = stridx(linestr, ":", idx_colon1 + 1)
        if (idx_colon2 < 1)
            call s:MsgError("incorrect format3")
            return
        endif
        let linenum= strpart(linestr, idx_colon1 + 1, idx_colon2 - idx_colon1 - 1)
    else
        let idx = stridx(linestr, " ")
        if (idx < 1)
            return
        endif
        let fname = strpart(linestr, 0, idx)
        let linestr = strpart(linestr, idx+1)
        let idx = stridx(linestr, " ")
        if (idx < 1)
            return
        endif
        let linenum= strpart(linestr, 0, idx)
    endif
    call s:OpenViewFile(fname, linenum, s:QueryBaseDir{s:cide_cur_sel_query})
endfunction

function! s:CreateWindow(cmd, bufname)
    set noequalalways 
    let cmdstr =  a:cmd." ".a:bufname
    exec cmdstr
    call s:GotoWindowByName(a:bufname)
    setlocal modifiable
endfunction

function! s:SetQueryResultWinSyntax()
    let &scrolloff = 0
    if has('syntax')

        syntax keyword QResTitle pattern
        if s:cide_cur_query_type == 'grep'
            syntax match QResFileName '^.\+:[1-9][0-9]*:' contains=QResFileNameWithColons,QResLineNumWithColons
            syntax match QResLineNumWithColons ':[1-9][0-9]*:' contained contains=QResLineNum
            syntax match QResLineNum '[1-9][0-9]*' contained
        else
            syntax match QResFileName '^\f\+\>' nextgroup=QResLineNum skipwhite
            syntax match QResLineNum '\<[1-9][0-9]*\>' contained nextgroup=QResFuncName skipwhite
        endif
        syntax match QResFuncName '\S\+' contained
        syntax match QResIndicatorMarker '\_^.\+<==\_$'
        "      syntax match QResLineNum '\<[1-9][0-9]*\>' contained nextgroup=QResLineContent skipwhite
        "      syntax match QResLineContent '\.*\$' contained nextgroup=QResLineContent skipwhite

        " Define the highlighting only if colors are supported
        if has('gui_running') || &t_Co > 2
            " Colors to highlight various taglist window elements If user defined highlighting group exists, then use them.
            " Otherwise, use default highlight groups.
            if hlexists('MyQResLineNum')
                highlight link QResLineNum MyQResLineNum
            else
                highlight clear QResLineNum
                highlight link QResLineNum keyword
            endif
            if hlexists('MyQResFuncName')
                highlight link QResFuncName MyQResFuncName
            else
                highlight clear QResFuncName
                highlight QResFuncName guifg=#00FFFF
            endif
            if hlexists('MyQResTite')
                highlight link QResTitle MyQResTitle
            else
                highlight clear QResTitle
                highlight link QResTitle keyword
            endif
            if hlexists('MyQResFileName')
                highlight link QResFileName MyQResFileName
            else
                highlight clear QResFileName
                highlight link QResFileName type
            endif
            if hlexists('MyQResIndicatorMarker')
                highlight link QResIndicatorMarker MyQResIndicatorMarker
            else
                highlight clear QResIndicatorMarker
                highlight QResIndicatorMarker guifg=#FFFF00 guibg=#0000FF
            endif
        else
            highlight QResActive term=reverse cterm=reverse
        endif
    endif
endfunction

" Initializes the query result window
function! s:InitQueryResultWin()
    call s:CreateWindow('botright 10new', s:CIDE_WIN_TITLE_QUERYRES)
    call append(0,"Results for ")
    setlocal nomodifiable
    silent! setlocal buftype=nofile
    silent! setlocal bufhidden=delete
    silent! setlocal noswapfile
    silent! setlocal nowrap
    silent! setlocal nonumber
    silent! setlocal nobuflisted
    nnoremap <buffer> <silent> <CR> :call <SID>CB_ViewCurrentQueryResultItem()<CR>
    nnoremap <buffer> <silent> <2-LeftMouse> :call <SID>CB_ViewCurrentQueryResultItem()<CR>
    " call s:SetQueryResultWinSyntax()
endfunction

" Initializes the query list window
function! s:InitQueryListWin()
    call s:CreateWindow('15vnew', s:CIDE_WIN_TITLE_QUERYLIST)
    "   call append(0,"Queries")
    setlocal nomodifiable
    silent! setlocal buftype=nofile
    silent! setlocal bufhidden=delete
    silent! setlocal noswapfile
    silent! setlocal nowrap
    silent! setlocal nonumber
    silent! setlocal nobuflisted
    nnoremap <buffer> <silent> <CR>             :call <SID>CB_SelectQuery()<CR>
    nnoremap <buffer> <silent> d                :call <SID>CB_DeleteQuery(0)<CR>
    nnoremap <buffer> <silent> u                :call <SID>CB_UpdateQuery()<CR>
    nnoremap <buffer> <silent> <2-LeftMouse>    :call <SID>CB_SelectQuery()<CR>

    if has('syntax')
        "      syntax match QListQueryCount '^[1-9][0-9]*)' nextgroup= QListQueryType
        "syntax match QListIndicatorMarker '\n.\+<==$'
        syntax keyword QListTitle Queries
        syntax match QListQueryCount '^[1-9][0-9]*' nextgroup=QListQueryType skipwhite
        syntax match QListQueryType '\S\+' contained nextgroup=QListQueryCase skipwhite
        syntax match QListQueryCase '\S\+' contained nextgroup=QListQueryPattern skipwhite
        syntax match QListQueryPattern '\S\+' contained
        syntax match QListIndicatorMarker '\_^.\+<==\_$'

        if has('gui_running') || &t_Co > 2
            if hlexists('MyQListQueryCount')
                highlight link QListQueryCount MyQListQueryCount
            else
                highlight clear QListQueryCount 
                highlight link QListQueryCount keyword
            endif
            if hlexists('MyQListTitle')
                highlight link QListTitle MyQListTitle
            else
                highlight clear QListTitle
                highlight link QListTitle keyword
            endif
            if hlexists('MyQListQueryType')
                highlight link QListQueryType MyQListQueryType
            else
                highlight clear QListQueryType
                highlight link QListQueryType type
            endif
            if hlexists('MyQListQueryPattern')
                highlight link QListQueryPattern MyQListQueryPattern
            else
                highlight clear QListQueryPattern
                highlight QListQueryPattern guifg=#80a0ff
            endif
            if hlexists('MyQListQueryCase')
                highlight link QListQueryCase MyQListQueryCase
            else
                highlight clear QListQueryCase
                highlight QListQueryCase guifg=#FFFFFF
            endif
            if hlexists('MyQListIndicatorMarker')
                highlight link QListIndicatorMarker MyQListIndicatorMarker
            else
                highlight clear QListIndicatorMarker
                highlight QListIndicatorMarker guifg=#FFFF00 guibg=#0000FF
            endif
        endif
    endif
endfunction

" Make sure both QueryList and QueryResult windows are opened
function! s:OpenQueryListQueryResult()
    let winNumQL = s:FindWindow(s:CIDE_WIN_TITLE_QUERYLIST)
    if winNumQL == -1
        "query list was not open
        let winNumQR = s:GotoWindowByName(s:CIDE_WIN_TITLE_QUERYRES)
        if (winNumQR == -1)
            call s:InitQueryResultWin()
        endif
        "query result is open now
        call s:InitQueryListWin()
    else
        "query list is open
        let winNumQR = s:FindWindow(s:CIDE_WIN_TITLE_QUERYRES)
        if winNumQR == -1
            "query list is open, but no query result
            "close the QueryList window
            call s:CloseWindow(winNumQL)
            "open the query result
            call s:InitQueryResultWin()
            "reopen the query list
            call s:InitQueryListWin()
        else
            "both window are open
        endif
    endif
    call s:GotoWindowByName(s:CIDE_WIN_TITLE_QUERYLIST)
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal bufhidden=delete
    setlocal nowrap
    setlocal nomodifiable
endfunction

function! s:CideClose()
    call s:CloseWindowByName(s:CIDE_WIN_TITLE_QUERYLIST)
    call s:CloseWindowByName(s:CIDE_WIN_TITLE_QUERYRES)
endfunction

function! s:CideToggle()
    let winNumQL = s:FindWindow(s:CIDE_WIN_TITLE_QUERYLIST)
    let winNumQR = s:FindWindow(s:CIDE_WIN_TITLE_QUERYRES)
    if ((winNumQL != -1) || (winNumQR != -1))
        call s:CideClose()
        return
    endif
    call s:OpenQueryListQueryResult()
    call s:RedrawQueryListQueryResult()
endfunction

function! s:MarkLine(lineno)
    " goto window
    let cmd = "%substitute/ ".s:CIDE_RES_IND_MARK."$//g"
    setlocal modifiable
    silent! exec cmd
    let curline = getline(a:lineno)
    call setline(a:lineno, curline." ".s:CIDE_RES_IND_MARK)
    setlocal nomodifiable
    " goto lineno
    exec a:lineno
endfunction

function! s:CB_SelectQuery()
    " Make sure it's called from QLIST window
    if bufname('%') != s:CIDE_WIN_TITLE_QUERYLIST 
        return 
    endif
    let save_rep = &report
    let save_sc  = &showcmd
    let &report    = 10000
    set noshowcmd 
    let curlineno = line(".")
    if curlineno < 1 || curlineno>s:cide_cur_query_count
        return
    endif
    " Make sure both query windows are open
    call s:OpenQueryListQueryResult()
    call s:PopulateQueryResult(curlineno)
    let resize = 0 " CHECKME
    let &report  = save_rep
    let &showcmd = save_sc
    call s:OpenQueryListQueryResult()	
    " move to beginning of line
    :normal 0
    call s:MarkLine(s:cide_cur_sel_query)
endfunction

function! s:InsertQuery(idx, cmdname, pat, cnt, tmpfile, basedir)
    let ii = s:cide_cur_query_count
    while (ii>=a:idx)
        let s:QueryCommand{ii+1} = s:QueryCommand{ii}
        let s:QueryPattern{ii+1} = s:QueryPattern{ii}
        let s:QueryNumFounds{ii+1} = s:QueryNumFounds{ii}
        let s:QueryCurIdx{ii+1} = s:QueryCurIdx{ii}
        let s:QueryResultFile{ii+1} = s:QueryResultFile{ii}
        let s:QueryBaseDir{ii+1} = s:QueryBaseDir{ii}
        let ii = ii - 1
    endwhile
    let s:QueryCommand{a:idx} = a:cmdname
    let s:QueryPattern{a:idx} = a:pat
    let s:QueryNumFounds{a:idx} = a:cnt
    let s:QueryCurIdx{a:idx} = 1
    let s:QueryResultFile{a:idx} = a:tmpfile
    let s:QueryBaseDir{a:idx} = a:basedir
    let s:cide_cur_query_count = s:cide_cur_query_count + 1

    " Make sure both query windows are open
    call s:OpenQueryListQueryResult()
    let nLines = s:PopulateQueryResult(a:idx)
    let s:QueryNumFounds{a:idx} = nLines
    let tstr = s:BuildQueryListItem(a:cmdname, nLines, a:pat)
    call s:OpenQueryListQueryResult()
    setlocal modifiable
    call append(a:idx-1, tstr)
    let lastlineno = line("$")
    let lastline = getline(lastlineno)
    let lastlinelen = strlen(lastline)
    if lastlinelen == 0
        exe lastlineno."d"
    endif
    exec a:idx
    call s:MarkLine(a:idx)
    setlocal nomodifiable
endfunction

function! s:CB_DeleteQuery(qid)
    if bufname('%') != s:CIDE_WIN_TITLE_QUERYLIST
        return 
    endif

    if (a:qid==0)
        let curlineno = line(".")
    else
        let curlineno = a:qid
    endif

    if (curlineno> s:cide_cur_query_count)
        return
    endif

    let ii = curlineno + 1
    while (ii <= s:cide_cur_query_count)
        let s:QueryCommand{ii-1} = s:QueryCommand{ii}
        let s:QueryPattern{ii-1} = s:QueryPattern{ii}
        let s:QueryNumFounds{ii-1} = s:QueryNumFounds{ii}
        let s:QueryCurIdx{ii-1} = s:QueryCurIdx{ii}
        let s:QueryResultFile{ii-1} = s:QueryResultFile{ii}
        let s:QueryBaseDir{ii-1} = s:QueryBaseDir{ii}
        let ii = ii +1
    endwhile
    unlet s:QueryCommand{s:cide_cur_query_count}
    unlet s:QueryPattern{s:cide_cur_query_count}
    unlet s:QueryNumFounds{s:cide_cur_query_count}
    unlet s:QueryCurIdx{s:cide_cur_query_count}
    unlet s:QueryResultFile{s:cide_cur_query_count}
    unlet s:QueryBaseDir{s:cide_cur_query_count}
    let s:cide_cur_query_count = s:cide_cur_query_count - 1
    "remove current line
    setlocal modifiable
    exe "delete"
    setlocal nomodifiable
    " move to beginning of line
    :normal 0
endfunction

function! s:CB_UpdateQuery()
    if bufname('%') != s:CIDE_WIN_TITLE_QUERYLIST
        return 
    endif

    let curlineno = line(".")
    if (curlineno> s:cide_cur_query_count)
        return
    endif
    call s:MsgInfo(s:QueryCommand{curlineno})
    return
    " TBD we can potentially restore last deleted item
    let ii = curlineno + 1
    while (ii <= s:cide_cur_query_count)
        let s:QueryCommand{ii-1} = s:QueryCommand{ii}
        let s:QueryPattern{ii-1} = s:QueryPattern{ii}
        let s:QueryNumFounds{ii-1} = s:QueryNumFounds{ii}
        let s:QueryCurIdx{ii-1} = s:QueryCurIdx{ii}
        let s:QueryResultFile{ii-1} = s:QueryResultFile{ii}
        let s:QueryBaseDir{ii-1} = s:QueryBaseDir{ii}
        let ii = ii +1
    endwhile
    unlet s:QueryCommand{s:cide_cur_query_count}
    unlet s:QueryPattern{s:cide_cur_query_count}
    unlet s:QueryNumFounds{s:cide_cur_query_count}
    unlet s:QueryCurIdx{s:cide_cur_query_count}
    unlet s:QueryResultFile{s:cide_cur_query_count}
    unlet s:QueryBaseDir{s:cide_cur_query_count}
    let s:cide_cur_query_count = s:cide_cur_query_count - 1
    "remove current line
    setlocal modifiable
    exe "delete"
    setlocal nomodifiable
    " move to beginning of line
    :normal 0
endfunction

function! s:CscopeRebuild()
    "  silent! call s:ExecVimCmdOutput("cs show")
    "  if (strpart(@z,0,2)!="no")
    "    silent! call s:ExecVimCmdOutput("cs kill -1")
    "    call delete(s:cide_cur_cscope_out_dir."/".s:CSCOPE_OUT_FNAME)
    "  else
    let curpath = s:FindFileInParentFolders(s:CSCOPE_OUT_FNAME)
    if strlen(curpath) > 3
        "delete existing cscope.out
        call delete(curpath."/".s:CSCOPE_OUT_FNAME)
    endif
    "  endif
    let ret0 = s:RebuildCscopeSub()
    if (ret0 == 0)
        return 0
    endif
endfunction

function! s:atoi(str)
    let cmd = "let tmpv=".a:str
    exec cmd
    return tmpv
endfunction

function! s:LoadHist(bAppend)
    if a:bAppend==1
        let fname = browse(0, "Append Cscope History File", "last", "*.his")
    else
        let fname = browse(0, "Load Cscope History File", "last", "*.his")
    endif
    if fname == ""
        return
    endif
    call s:OpenQueryListQueryResult()
    "open a 0 heigh window split in Hist
    call s:CreateWindow('0new', 'tempwin__')
    "   redraw
    """"""""""""""""""""""" Get the file into tstr
    let bn=bufnr("%")
    "setlocal modifiable
    exe "e ".fname
    norm ggVG"zy
    "   exe "bd!|b ".bn
    let tstr=@z
    "   call s:MsgInfo(@z)
    :q!
    """""""""""""""""""""""" Save old QueryCount
    let OldQueryCount = s:cide_cur_query_count
    if (a:bAppend==0)
        """""""""""""""""""""""" Reset QueryCount
        let s:cide_cur_query_count = 0
        setlocal modifiable
        silent exe '1,$delete'
        setlocal nomodifiable
    endif

    """""""""""""""""""""""" Load tstr into query arrays
    while (1==1)
        let ixn = stridx(tstr, "\n")
        if (ixn < 0)
            break
        endif

        let linestr = strpart(tstr, 0, ixn)
        let idx = stridx(linestr, "\t")
        if (idx >= 0)
            let str_cmd = strpart(linestr, 0, idx) 
            let linestr = strpart(linestr, idx+1) 
            let idx = stridx(linestr, "\t")
            if (idx >= 0)
                let str_pat = strpart(linestr, 0, idx)
                let linestr = strpart(linestr, idx+1) 
                let idx = stridx(linestr, "\t")
                if (idx >= 0)
                    let str_cnt = strpart(linestr, 0, idx)
                    let linestr = strpart(linestr, idx+1) 
                    let idx = stridx(linestr, "\t")
                    if (idx >= 0)
                        let str_tfile = strpart(linestr, 0, idx) 
                        let str_basedir = strpart(linestr, idx+1) 
                        if strlen(str_basedir)<2
                            let idx = -1
                        endif
                    endif
                endif
            endif
        endif
        if idx>=0
            let ccnntt = s:atoi(str_cnt)
            call s:InsertQuery(1, str_cmd, str_pat, str_cnt, str_tfile, str_basedir)
        endif
        let tstr = strpart(tstr, ixn+1)
    endwhile
    "unlet unused elements (if there is any)
    let ii = s:cide_cur_query_count + 1
    while (ii<=OldQueryCount)
        unlet s:QueryCommand{ii}
        unlet s:QueryPattern{ii}
        unlet s:QueryNumFounds{ii}
        unlet s:QueryCurIdx{ii}
        unlet s:QueryResultFile{ii}
        unlet s:QueryBaseDir{ii}
        let ii = ii + 1
    endwhile
endfunction

function! <SID>SaveHist()
    let fname = browse(1, "Save Cscope History File", "last", "*.his")
    if fname == ""
        return
    endif
    let ii = 1
    let tstr = ""
    while (ii <= s:cide_cur_query_count)
        let tstr = tstr . s:QueryCommand{ii}
        let tstr = tstr . "\t"
        let tstr = tstr . s:QueryPattern{ii}
        let tstr = tstr . "\t"
        let tstr = tstr . s:QueryNumFounds{ii}
        let tstr = tstr . "\t"
        let tstr = tstr . s:QueryResultFile{ii}
        let tstr = tstr . "\t"
        let tstr = tstr . s:QueryBaseDir{ii}
        let tstr = tstr . "\n"
        let ii = ii +1
    endwhile
    call s:SaveStrToFile(tstr, fname)
endfunction

function! s:CscopeCase()
    "	echo "cur=" . a:cur
    if s:cide_flag_cscope_case == 1
        let s:cide_flag_cscope_case =  0
        unmenu &CIDE.CscopeCase
        menu <silent> &CIDE.CscopeNoCase :CscopeCase<CR>
    else
        let s:cide_flag_cscope_case =  1
        unmenu &CIDE.CscopeNoCase
        menu <silent> &CIDE.CscopeCase :CscopeCase<CR>	
    endif
endfunction

function! s:UniqueNames()
    "	echo "cur=" . a:cur
    if s:cide_flag_unique_names == 1
        let s:cide_flag_unique_names =  0
        unmenu CodeTree.UniqueName
        menu <silent> CodeTree.NonuniqueName :MyUniqueNames<CR>
        "menu C&odeTree.NonuniqueName :MyUniqueNames<CR>
    else
        let s:cide_flag_unique_names =  1
        unmenu CodeTree.NonuniqueName
        menu <silent> CodeTree.UniqueName :MyUniqueNames<CR>	
    endif
endfunction

" ==== codetree implementation ===

let s:getnextidcurid = 0
function! s:GetNextID()
    let s:getnextidcurid = s:getnextidcurid + 1
    return s:getnextidcurid
endfunction

let s:Node_{0}_{0}_Name=s:CIDE_WIN_TITLE_CALLEETREE
let s:Node_{0}_{0}_File=""
let s:Node_{0}_{0}_LineNo=0
let s:Node_{0}_{0}_DefFile=""
let s:Node_{0}_{0}_DefLineNo=0
let s:Node_{0}_{0}_idParent=-1
let s:Node_{0}_{0}_nChilds=0
let s:Node_{0}_{0}_bQuestion=0
let s:Node_{0}_{0}_bFolded=0
let s:Node_{1}_{0}_Name=s:CIDE_WIN_TITLE_CALLERTREE
let s:Node_{1}_{0}_File=""
let s:Node_{1}_{0}_LineNo=0
let s:Node_{1}_{0}_DefFile=""
let s:Node_{1}_{0}_DefLineNo=0
let s:Node_{1}_{0}_idParent=-1
let s:Node_{1}_{0}_nChilds=0
let s:Node_{1}_{0}_bQuestion=0
let s:Node_{1}_{0}_bFolded=0

let s:idCurSelectCodeTreeNode_{0}=0
let s:idCurSelectCodeTreeNode_{1}=0

function! s:InsertBlank(iType, idparent, iNew)
    let i = s:Node_{a:iType}_{a:idparent}_nChilds
    while (i>=a:iNew)
        let s:Node_{a:iType}_{a:idparent}_Child_{i+1} = s:Node_{a:iType}_{a:idparent}_Child_{i}
        unlet s:Node_{a:iType}_{a:idparent}_Child_{i}
        let i = i - 1
    endwhile
    let s:Node_{a:iType}_{a:idparent}_Child_{a:iNew} = -2
    let s:Node_{a:iType}_{a:idparent}_nChilds = s:Node_{a:iType}_{a:idparent}_nChilds + 1
endfunction

function! s:AddChild(iType, idparent, iNew, name, file, lineno)
    if(a:idparent==-1)
        let idparent=0
    else
        let idparent = a:idparent
    endif
    let iNew = a:iNew
    if(iNew < 0)
        let iNew = s:Node_{a:iType}_{idparent}_nChilds + 1
    endif
    call s:InsertBlank(a:iType, idparent, iNew)
    let newid = s:GetNextID()
    let s:Node_{a:iType}_{newid}_Name = a:name
    let s:Node_{a:iType}_{newid}_File = a:file
    let s:Node_{a:iType}_{newid}_LineNo = a:lineno
    let s:Node_{a:iType}_{newid}_DefFile = ""
    let s:Node_{a:iType}_{newid}_DefLineNo = 0
    let s:Node_{a:iType}_{newid}_idParent = idparent
    let s:Node_{a:iType}_{newid}_nChilds = 0
    let s:Node_{a:iType}_{newid}_bQuestion = 1
    let s:Node_{a:iType}_{newid}_bFolded = 0
    let s:Node_{a:iType}_{idparent}_Child_{iNew} = newid
    return newid
endfunction

function! s:AddChildCopy(iType, idparent, iNew, idFrom)
    if(a:idparent==-1)
        let idparent=0
    else
        let idparent = a:idparent
    endif
    let iNew = a:iNew
    if(iNew < 0)
        let iNew = s:Node_{a:iType}_{idparent}_nChilds + 1
    endif
    call s:InsertBlank(a:iType, idparent, iNew)
    let newid = s:GetNextID()
    let s:Node_{a:iType}_{newid}_Name = s:Node_{a:iType}_{a:idFrom}_Name
    let s:Node_{a:iType}_{newid}_File = s:Node_{a:iType}_{a:idFrom}_File
    let s:Node_{a:iType}_{newid}_LineNo = s:Node_{a:iType}_{a:idFrom}_LineNo
    let s:Node_{a:iType}_{newid}_DefFile = s:Node_{a:iType}_{a:idFrom}_DefFile
    let s:Node_{a:iType}_{newid}_DefLineNo = s:Node_{a:iType}_{a:idFrom}_DefLineNo
    let s:Node_{a:iType}_{newid}_idParent = idparent
    let s:Node_{a:iType}_{newid}_nChilds = s:Node_{a:iType}_{a:idFrom}_nChilds
    let s:Node_{a:iType}_{newid}_bQuestion = s:Node_{a:iType}_{a:idFrom}_bQuestion
    let s:Node_{a:iType}_{newid}_bFolded = s:Node_{a:iType}_{a:idFrom}_bFolded
    let s:Node_{a:iType}_{idparent}_Child_{iNew} = newid

    "update parent of all children
    let i = 1
    let n = s:Node_{a:iType}_{newid}_nChilds
    while (i<=n)
        let childid = s:Node_{a:iType}_{a:idFrom}_Child_{i}
        let s:Node_{a:iType}_{newid}_Child_{i} = childid
        unlet s:Node_{a:iType}_{a:idFrom}_Child_{i}
        let s:Node_{a:iType}_{childid}_idParent = newid
        let i = i + 1
    endwhile
    return newid
endfunction

function! s:GetIdx(iType, id)
    let idparent = s:Node_{a:iType}_{a:id}_idParent
    let i = 1
    let n = s:Node_{a:iType}_{idparent}_nChilds
    while (i<=n)
        if (s:Node_{a:iType}_{idparent}_Child_{i} == a:id)
            return i
        endif
        let i = i + 1
    endwhile
    return -1
endfunction

function! s:DeleteBlank(iType, id)
    let idparent = s:Node_{a:iType}_{a:id}_idParent
    let idx = s:GetIdx(a:iType, a:id)
    if (idx < 0) 
        echo "invalid id in DeleteBlank()"
        return
    endif
    let i = idx
    let n = s:Node_{a:iType}_{idparent}_nChilds
    while (i<n)
        let s:Node_{a:iType}_{idparent}_Child_{i} = s:Node_{a:iType}_{idparent}_Child_{i+1}
        let i = i + 1
    endwhile
    unlet s:Node_{a:iType}_{idparent}_Child_{n}
    let s:Node_{a:iType}_{idparent}_nChilds = s:Node_{a:iType}_{idparent}_nChilds - 1
endfunction

function! s:DeleteNode(iType, id)
    if(a:id <1)
        return
    endif
    if(a:id == s:idCurSelectCodeTreeNode_{a:iType})
        let s:idCurSelectCodeTreeNode_{a:iType}=-1
    endif
    let n = s:Node_{a:iType}_{a:id}_nChilds
    if(n>0)
        "      echo "can not delete non-empty node"
        "      return
    end
    call s:DeleteBlank(a:iType, a:id)
    unlet s:Node_{a:iType}_{a:id}_Name
    unlet s:Node_{a:iType}_{a:id}_File
    unlet s:Node_{a:iType}_{a:id}_LineNo
    unlet s:Node_{a:iType}_{a:id}_DefFile
    unlet s:Node_{a:iType}_{a:id}_DefLineNo
    unlet s:Node_{a:iType}_{a:id}_idParent
    unlet s:Node_{a:iType}_{a:id}_nChilds
    unlet s:Node_{a:iType}_{a:id}_bQuestion
    unlet s:Node_{a:iType}_{a:id}_bFolded
endfunction

function! s:DeleteAllSub(iType, id, bDeleteSelf)
    let i = s:Node_{a:iType}_{a:id}_nChilds
    while(i>=1)
        call s:DeleteAllSub(a:iType, s:Node_{a:iType}_{a:id}_Child_{i}, 1)
        let i = i-1
    endwhile
    if(a:bDeleteSelf==1)
        call s:DeleteNode(a:iType, a:id)
    endif
endfunction

function! s:DeleteAll(bDeleteSelf)
    let ret0 = confirm("Are you sure want to delete it?","Yes\nNo")
    if(ret0 != 1)
        return
    endif
    let iType = s:GetCodeTreeWin()
    if (iType < 0) 
        return
    endif
    let curline = line(".")
    let curid = s:GetNodeID(iType, curline)
    if(curid<0)
        return
    endif
    call s:DeleteAllSub(iType, curid, a:bDeleteSelf)
    call s:UpdateCodeTree(iType)
endfunction

function! s:UpdateCodeTreeSub(iType, idcurnode, iLevel, bLastChild)
    let n = s:Node_{a:iType}_{a:idcurnode}_nChilds
    "echo s:Node_{a:idcurnode}_Name." has ".n." childs"
    let curline = line("$")
    if (a:idcurnode == s:idCurSelectCodeTreeNode_{a:iType})
        let postfix = "*"
    else
        if (s:Node_{a:iType}_{a:idcurnode}_bQuestion == 1)
            let postfix = "?"
        elseif (s:Node_{a:iType}_{a:idcurnode}_bQuestion == 2)
            let postfix = "@"
        else
            let postfix = "!"
        endif
    endif
    let bRet = 0
    if (a:idcurnode==0)
        let prefix = ""
    else
        if (s:Node_{a:iType}_{a:idcurnode}_bFolded == 1 && s:Node_{a:iType}_{a:idcurnode}_nChilds>0 )
            if (a:iType == 0)
                let prefix = "|+>"
            else
                let prefix = "|<+"
            endif
            let bRet = 1
        else
            if (a:iType == 0)
                let prefix = "|->"
            else
                let prefix = "|<-"
            endif
        endif
        if(s:Node_{a:iType}_{a:idcurnode}_File=="")
            "let prefix = substitute(prefix,"<"," ","g")
            "let prefix = substitute(prefix,">"," ","g")
        endif
        if(s:Node_{a:iType}_{a:idcurnode}_DefFile=="")
            if(s:Node_{a:iType}_{a:idcurnode}_DefLineNo==0)
                let prefix = prefix."."
            else
                let prefix = prefix."$"
            endif
        else
            let prefix = prefix."="
        endif
    endif

    "   if (a:idcurnode==0)
    let describ = ""
    "   else
    "      let describ = " [".s:Node_{a:iType}_{a:idcurnode}_File." ".s:Node_{a:iType}_{a:idcurnode}_LineNo."]"
    "   endif
    call append(curline, a:iLevel.prefix.s:Node_{a:iType}_{a:idcurnode}_Name.postfix.describ)
    if (bRet==1)
        return
    endif
    "echo a:iLevel.s:Node_{a:idcurnode}_Name
    if(a:bLastChild==1)
        let tstr = a:iLevel."   "
    else
        let tstr = a:iLevel."|  "
    endif
    let i = 1
    while (i<n)
        call s:UpdateCodeTreeSub(a:iType, s:Node_{a:iType}_{a:idcurnode}_Child_{i}, tstr, 0)
        let i = i + 1
    endwhile
    if(n>0)
        call s:UpdateCodeTreeSub(a:iType, s:Node_{a:iType}_{a:idcurnode}_Child_{n}, tstr, 1)
    endif
endfunction

function! s:UpdateCodeTree(iType)
    call s:OpenCodeTree(a:iType)
    let curline = line(".")
    setlocal modifiable
    silent exe '1,$delete'
    call s:UpdateCodeTreeSub(a:iType, 0, "", 1)
    1d
    setlocal nomodifiable
    exec curline
endfunction

function! s:MoveDULR(bDir)
    let iType = s:GetCodeTreeWin()
    if (iType < 0) 
        return
    endif

    let curline = line(".")
    let curid = s:GetNodeID(iType, curline)
    if(curid<0)
        return
    endif

    let idParent = s:Node_{iType}_{curid}_idParent
    if (idParent<0)
        return
    endif

    let curidx = s:GetIdx(iType, curid)
    if (curidx <= 0) 
        echo "invalid id in MoveDULR()"
        return
    endif

    if (a:bDir<=1)
        if (a:bDir==1) " up
            let newidx = curidx-1
        else           " down
            let newidx=curidx+1
        endif
        if(newidx<=0 || newidx > s:Node_{iType}_{idParent}_nChilds)
            return
        endif
        let temp = s:Node_{iType}_{idParent}_Child_{curidx}
        let s:Node_{iType}_{idParent}_Child_{curidx} = s:Node_{iType}_{idParent}_Child_{newidx}
        let s:Node_{iType}_{idParent}_Child_{newidx} = temp
        let newid = s:Node_{iType}_{idParent}_Child_{newidx}
    else
        if (a:bDir==2) " left
            if (idParent==0)
                return
            endif
            let idNewParent = s:Node_{iType}_{idParent}_idParent
        else           " right
            if (curidx <= 1) 
                return
            endif
            let idNewParent = s:Node_{iType}_{idParent}_Child_{curidx-1}
        endif
        let newid = s:AddChildCopy(iType, idNewParent, -1, curid)
        call s:DeleteNode(iType, curid)
        "call s:DeleteBlank(iType, curid)
    endif

    call s:SetCurSelectNode(iType, newid, 0)
    call s:UpdateCodeTree(iType)
    let newline = s:GetNodeLine(iType, newid)
    exec newline
endfunction

" Initializes the query list window
function! s:InitCodeTreeWin()
    setlocal nomodifiable
    silent! setlocal buftype=nofile
    silent! setlocal bufhidden=delete
    silent! setlocal noswapfile
    silent! setlocal nowrap
    silent! setlocal nonumber
    silent! setlocal nobuflisted
    nnoremap <buffer> <silent> <CR> :call <SID>CodeTreeSelect()<CR>
    nnoremap <buffer> <silent> e :call <SID>ExpandTree()<CR>
    nnoremap <buffer> <silent> <C-J> :call <SID>MoveDULR(0)<CR>
    nnoremap <buffer> <silent> <C-K> :call <SID>MoveDULR(1)<CR>
    nnoremap <buffer> <silent> <C-H> :call <SID>MoveDULR(2)<CR>
    nnoremap <buffer> <silent> <C-L> :call <SID>MoveDULR(3)<CR>
    nnoremap <buffer> <silent> d :call <SID>DeleteSubtree()<CR>
    nnoremap <buffer> <silent> <2-LeftMouse> :call <SID>CodeTreeSelect()<CR>
    "nnoremap <buffer> <silent> d :call <SID>CB_DeleteQuery(0)<CR>
    if has('syntax')
        "      syntax match SyntaxFuncName0 ']\S\+?' contains=SyntaxFuncName 
        syntax match SyntaxFileName '\[\zs\S\+\ze\ '
        syntax match SyntaxFuncName '\.\zs\S\+\ze?'
        syntax match SyntaxFuncNameOK '\.\zs\S\+\ze!'
        syntax match SyntaxFuncNameDef '=\zs\S\+\ze'
        "      syntax match SyntaxFuncNameOK '!'
        syntax match SyntaxFuncNameCur1 '\.\zs\S\+\ze\*'
        syntax match SyntaxFuncNameCur2 '=\zs\S\+\ze\*'
        syntax match SyntaxFuncNameCurRoot '^\S\+\ze\*'
        "      syntax match SyntaxFuncNameOK0 '->\S\+!'
        "      syntax match SyntaxFuncNameOK1 '<-\S\+!'
        syntax match SyntaxFuncNameFolded0 '+>.\+!'
        syntax match SyntaxFuncNameFolded1 '<+.\+!'
        syntax match SyntaxCalleeTreeRoot '^Callees!$'
        syntax match SyntaxCallerTreeRoot '^Callers!$'
        if has('gui_running') || &t_Co > 2
            highlight SyntaxFuncName guifg=#6699FF
            highlight SyntaxFileName guifg=#FF66CC
            "	highlight SyntaxFuncNameOK0 guifg=#00FF00
            highlight SyntaxFuncNameOK guifg=#00FF00
            highlight SyntaxFuncNameDef guifg=#FFFF00
            highlight SyntaxFuncNameCur1 guifg=#00FF00 guibg=#990033
            highlight SyntaxFuncNameCur2 guifg=#00FF00 guibg=#990033
            highlight SyntaxFuncNameCurRoot guifg=#00FF00 guibg=#990033
            highlight SyntaxFuncNameFolded0 guifg=#FF0000
            highlight SyntaxFuncNameFolded1 guifg=#FF0000
            "	highlight link SyntaxCalleeTreeRoot comment 
            "	highlight link SyntaxCallerTreeRoot comment
        endif
    endif
endfunction

function! s:GotoCodeTreeWinNo(iType)
    if (a:iType == 0)
        let winNumCT = s:FindWindow(s:CIDE_WIN_TITLE_CALLEETREE)
    else
        let winNumCT = s:FindWindow(s:CIDE_WIN_TITLE_CALLERTREE)
    endif
    call s:GotoWindow(winNumCT)
endfunction

"make sure the QueryWindow is not opened alone
function! s:OpenCodeTree(iType)
    let winNumCTe = s:FindWindow(s:CIDE_WIN_TITLE_CALLEETREE)
    let winNumCTr = s:FindWindow(s:CIDE_WIN_TITLE_CALLERTREE)
    let bNew = 1
    if (winNumCTe>0)
        if (winNumCTr>0)
            let bNew = 0
        else
            call s:CloseWindow(winNumCTe)
        endif
    else
        if (winNumCTr>0)
            call s:CloseWindow(winNumCTr)
        endif
    endif
    if (bNew == 1)
        let winnum = s:GetCodeWindow()
        if winnum == -1
            echo "ACS window not found!"
            return 0
        endif
        redraw
        call s:GotoWindow(winnum)
        call s:CreateWindow('botright 10new', s:CIDE_WIN_TITLE_CALLERTREE)
        "      exec 'botright 10new '. s:CIDE_WIN_TITLE_CALLERTREE
        redraw
        call s:InitCodeTreeWin()
        call s:CreateWindow('vnew', s:CIDE_WIN_TITLE_CALLEETREE)
        call s:InitCodeTreeWin()
        redraw
    endif
    call s:GotoCodeTreeWinNo(a:iType)
    return 1
endfunction

function! s:GetCodeTreeWin()
    let aa = bufname("%")
    if (aa == s:CIDE_WIN_TITLE_CALLEETREE)
        return 0 
    elseif (aa == s:CIDE_WIN_TITLE_CALLERTREE)
        return 1
    else
        return -1
    endif
endfunction

let s:getnodeidcurline = 1
function! s:GetNodeIDSub(iType, idparent, lineno)
    if(a:lineno == s:getnodeidcurline)
        return a:idparent
    endif
    let s:getnodeidcurline = s:getnodeidcurline + 1
    let i = 1
    let n = s:Node_{a:iType}_{a:idparent}_nChilds
    if (s:Node_{a:iType}_{a:idparent}_bFolded==0)
        while (i<=n)
            let retid=s:GetNodeIDSub(a:iType,s:Node_{a:iType}_{a:idparent}_Child_{i},a:lineno)
            if (retid>0)
                return retid
            endif
            let i = i + 1
        endwhile
    endif
    return -1
endfunction

function! s:GetNodeID(iType, lineno)
    let s:getnodeidcurline = 1
    return s:GetNodeIDSub(a:iType, 0, a:lineno)
endfunction

function! s:GetNodeLineSub(iType, idparent, targetid) 
    if(a:idparent == a:targetid)
        return s:getnodeidcurline
    endif
    let s:getnodeidcurline = s:getnodeidcurline + 1
    let i = 1
    let n = s:Node_{a:iType}_{a:idparent}_nChilds
    if (s:Node_{a:iType}_{a:idparent}_bFolded==0)
        while (i<=n)
            let retid=s:GetNodeLineSub(a:iType,s:Node_{a:iType}_{a:idparent}_Child_{i},a:targetid)
            if (retid>0)
                return retid
            endif
            let i = i + 1
        endwhile
    endif
    return -1
endfunction

function! s:GetNodeLine(iType, nodeid)
    let s:getnodeidcurline = 1
    return s:GetNodeLineSub(a:iType, 0, a:nodeid)
endfunction

let s:CTcounts = 0
"let s:CTfile_{} = 0
"let s:CTline_{} = 0
"let s:CTfunc_{} = 0
"let s:CTtext_{} = 0

function! s:GetCscopeResultList(cmd_num, patt)
    let s:CTcounts = 0
    let retcode = s:GetCscopeResult(a:cmd_num, a:patt, 0)
    if (retcode==0)
        return
    endif

    let cmd_output = s:cscope_cmd_out
    let cnt = 1
    while (1==1)
        let ixn = stridx(cmd_output, "\n")
        if (ixn < 0) 
            break
        endif
        let newline = strpart(cmd_output, 0, ixn)
        let jj=1
        while(jj<=3)
            let idx = stridx(newline, " ")
            if(idx>=0)
                let part_{jj} = strpart(newline, 0, idx)
                let newline = strpart(newline, idx+1)
            else
                break
            endif
            let jj = jj + 1
        endwhile
        if(jj>3)
            let kk=1
            while(kk<cnt)
                if (part_{2} == s:CTfunc_{kk})
                    if(s:cide_flag_unique_names==1 || s:cide_flag_unique_names==0 && part_{1} == s:CTfile_{kk} && part_{3} == s:CTline_{kk})
                        break
                    endif
                endif
                let kk = kk + 1
            endwhile
            if(kk>=cnt)
                let s:CTfile_{cnt} = part_{1}
                let s:CTline_{cnt} = part_{2}
                let s:CTfunc_{cnt} = part_{3}
                let s:CTtext_{cnt} = newline
                let cnt = cnt + 1
            endif
        endif
        let cmd_output = strpart(cmd_output, ixn+1)
    endwhile
    let s:CTcounts = cnt - 1
endfunction

function! s:SetCurSelectNode(iType, id, bUpdate)
    let oldid = s:idCurSelectCodeTreeNode_{a:iType}
    let s:idCurSelectCodeTreeNode_{a:iType} = a:id
    if(a:bUpdate)
        call s:UpdateCodeTree(a:iType)
        let i=1
    endif
endfunction

function! s:ExpandTreeSub(iType, curid)
    let curid0 = a:curid
    let curnodename = s:Node_{a:iType}_{curid0}_Name
    while(1==1)
        let curid0 = s:Node_{a:iType}_{curid0}_idParent
        if (curid0 == -1)
            break
        endif
        if (curnodename == s:Node_{a:iType}_{curid0}_Name)
            break
        endif
    endwhile

    if(curid0 != -1) "recursive call
        let s:Node_{a:iType}_{curid0}_bQuestion = 2
        let s:Node_{a:iType}_{a:curid}_bQuestion = 2
        return
    endif

    if (a:iType==0)
        let cscode = 2
    else
        let cscode = 3 
    endif
    call s:GetCscopeResultList(cscode, s:Node_{a:iType}_{a:curid}_Name)
    let i=1
    while(i<=s:CTcounts)
        let j=1
        let n = s:Node_{a:iType}_{a:curid}_nChilds
        while(j<=n)
            let childid= s:Node_{a:iType}_{a:curid}_Child_{j}
            if (s:CTfunc_{i} == s:Node_{a:iType}_{childid}_Name)
                if(s:cide_flag_unique_names==1 || s:cide_flag_unique_names==0 && s:CTfile_{i}==s:Node_{a:iType}_{childid}_File && s:CTline_{i}==s:Node_{a:iType}_{childid}_LineNo)
                    break
                endif
            endif
            let j=j+1
        endwhile
        if(j>n)
            call s:AddChild(a:iType, a:curid, -1, s:CTfunc_{i}, s:CTfile_{i}, s:CTline_{i})
        endif
        let i = i + 1
    endwhile
    let s:Node_{a:iType}_{a:curid}_bQuestion = 0
endfunction

function! s:ExpandTree()
    let iType = s:GetCodeTreeWin()
    if (iType < 0) 
        return
    endif
    call s:OpenCodeTree(iType)
    let curline = line(".")
    let curcol = col(".")
    let curid = s:GetNodeID(iType, curline)
    if(curid<0)
        return
    endif
    call s:ExpandTreeSub(iType, curid)
    call s:SetCurSelectNode(iType, curid, 0)
    call s:UpdateCodeTree(iType)
    exec curline
endfunction

function! s:CodeTreeSelect()
    let curline = line(".")
    let curcol = col(".")
    let iType = s:GetCodeTreeWin()
    if (iType < 0) 
        return
    endif
    let curid = s:GetNodeID(iType, curline)
    if(curid<0)
        return
    endif
    let cursel = getline(line("."))[col(".") - 1]
    call s:SetCurSelectNode(iType, curid, 1)
    if (cursel=="<" || cursel==">")
        call s:OpenViewFile(s:Node_{iType}_{curid}_File, s:Node_{iType}_{curid}_LineNo, s:cide_cur_cscope_out_dir) 
    else
        if (s:Node_{iType}_{curid}_DefFile == "")
            call s:GetDef()
            if (s:CTcounts>0)
                call s:OpenViewFile(s:Node_{iType}_{curid}_DefFile, s:Node_{iType}_{curid}_DefLineNo, s:cide_cur_cscope_out_dir) 
            endif
        else
            call s:OpenViewFile(s:Node_{iType}_{curid}_DefFile, s:Node_{iType}_{curid}_DefLineNo, s:cide_cur_cscope_out_dir) 
        endif
    endif
endfunction

function! s:ToggleFold()
    let curline = line(".")
    let curcol = col(".")
    let iType = s:GetCodeTreeWin()
    if (iType < 0) 
        return
    endif
    let curid = s:GetNodeID(iType, curline)
    if(curid<0)
        return
    endif
    call s:SetCurSelectNode(iType, curid, 0)
    let s:Node_{iType}_{curid}_bFolded = 1 - s:Node_{iType}_{curid}_bFolded
    call s:UpdateCodeTree(iType)
    "   exec curline
endfunction

function! s:DeleteSubtree()
    call s:DeleteAll(1)
endfunction

function! s:DeleteUnder()
    call s:DeleteAll(0)
endfunction

function! s:ClearRedundant()
    let curline = line(".")
    let curcol = col(".")
    let iType = s:GetCodeTreeWin()
    if (iType < 0) 
        return
    endif
    let curid = s:GetNodeID(iType, curline)
    if(curid<0)
        return
    endif
    let n=s:Node_{iType}_{curid}_nChilds
    let i=2
    while(i<=s:Node_{iType}_{curid}_nChilds)
        let j=1
        while(j<i)
            let j = j+1
        endwhile
        let i = i+1
    endwhile
    let s:Node_{iType}_{curid}_bFolded = 1 - s:Node_{iType}_{curid}_bFolded
    call s:UpdateCodeTree(iType)
    exec curline
endfunction

function! s:NewSymbol(iType)
    let  newsymb = input("Enter the name of new symbol: ", expand("<cword>"))
    if(newsymb == "")
        return
    endif
    let id3 = s:AddChild(a:iType, s:idCurSelectCodeTreeNode_{a:iType}, -1, newsymb, "", 0)
    call s:ExpandTreeSub(a:iType, id3)
    call s:SetCurSelectNode(a:iType, id3, 0)
    call s:UpdateCodeTree(a:iType)
endfunction

function! s:GetDef()
    let iType = s:GetCodeTreeWin()
    if (iType < 0) 
        return 0
    endif
    let curline = line(".")
    let curid = s:GetNodeID(iType, curline)
    if(curid<0)
        return 0
    endif
    if (s:Node_{iType}_{curid}_DefFile != "" || s:Node_{iType}_{curid}_DefLineNo==-1)
        return 0
    endif
    call s:GetCscopeResultList(1, s:Node_{iType}_{curid}_Name)
    if (s:CTcounts < 1)
        let s:Node_{iType}_{curid}_DefFile = ""
        let s:Node_{iType}_{curid}_DefLineNo = -1
    else
        let s:Node_{iType}_{curid}_DefFile = s:CTfile_{1}
        let s:Node_{iType}_{curid}_DefLineNo = s:CTline_{1}
    endif
    call s:SetCurSelectNode(iType, curid, 0)
    call s:UpdateCodeTree(iType)
    return s:CTcounts
endfunction

function! s:RunGrepSub()
    " call s:MsgInfo(expand('<sfile>'))
    " call s:MsgInfo(substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', ''))

    let ret = s:RunGrepSubSub(s:grep_opt_files)
    if s:cscope_cmd_out == ""
        call s:MsgError("pattern \"" . s:grep_pattern . "\" was not found")
        return 0
    endif
endfunction

function! s:RunGrepSubSub(grep_files)
    let grep_opt    = "--numbers --nocolor --nogroup"
    if (s:grep_opt_whole == 1)
        let grep_opt = grep_opt." --word-regexp"    " -w
    else
    endif
    if (s:grep_opt_icase == 0)
        let grep_opt = grep_opt." --ignore-case"    " -i
    else
        let grep_opt = grep_opt." --case-sensitive" " -s
    endif
    if (s:grep_opt_regex == 1)
        " let grep_opt = grep_opt."e"
    else
        let grep_opt = grep_opt." --literal"
    endif
    if (s:grep_opt_recurse == 1)
        let grep_opt = grep_opt." --recurse"        " -r
    else
        let grep_opt = grep_opt." --norecurse"      " -n
    endif

    let pattern  = s:CIDE_SHELL_QUOTE_CHAR . s:grep_pattern . s:CIDE_SHELL_QUOTE_CHAR
    " let filespec = s:CIDE_SHELL_QUOTE_CHAR . a:grep_files . s:CIDE_SHELL_QUOTE_CHAR
    let filespec = a:grep_files

    "  let cmd = "grex ".pattern." . ".a:grep_files.grep_opt
    let cmd = s:cide_shell_ag.' '.grep_opt.' '.filespec.' '.pattern

    if (s:grep_repby != "")
        let cmd = cmd . " ".s:grep_repby
    endif

    let oldpath = s:ChangeDirectory(s:grep_opt_dir) " save original directory
    let s:cscope_cmd_out = system(cmd)
    call s:ChangeDirectory(oldpath) " restore original directory

    if (s:cscope_cmd_out == "" || strlen(s:cscope_cmd_out)<5)
        return 0
    endif
    return 1
endfunction

function! s:GetOptionStr()
    let caseopt = " "
    let wordopt = " "
    let regeopt = " "
    let recuopt = " "
    if (s:grep_opt_icase == 1)
        let caseopt = "X"
    endif
    if (s:grep_opt_whole == 1)
        let wordopt = "X"
    endif
    if (s:grep_opt_regex == 1)
        let regeopt = "X"
    endif
    if (s:grep_opt_recurse == 1)
        let recuopt = "X"
    endif
    let str = " Case[".caseopt."] whole-Word[".wordopt."] rEgexp[".regeopt."] Recursive[".recuopt."]       <<Ok>>  <<Cancel>>"
  " let str =     [
  "          \   "[" . caseopt . "] Case" , 
  "          \   "[" . wordopt . "] Whole",
  "          \   "[" . regeopt . "] Regex",
  "          \   "[" . recuopt . "] Recur",
  "          \   " <<OK>>  <<Cancel>>"
  "          \   ]
    return str
endfunction

function! s:UpdateGrepOptWin(cl,val)
    let val = a:val
    setlocal modifiable
    exec "normal ".a:cl."|"
    if (val == 0)
        let val = ' '
    else
        let val = 'X'
    endif
    let cl_prev = a:cl - 1
    let newline = substitute(getline('.'), '^\(.\{' . cl_prev . '}\).', '\1'. val, 'g')
    call setline(line('.'), newline)
    setlocal nomodifiable
endfunction

let s:grep_opt_name_icase_1 = 'c'
let s:grep_opt_name_icase_0 = 'n'
let s:grep_opt_name_whole_1 = 'w'
let s:grep_opt_name_whole_0 = ''
let s:grep_opt_name_recurse_1 = 'r'
let s:grep_opt_name_recurse_0 = ''
let s:grep_opt_name_regex_1 = 'e'
let s:grep_opt_name_regex_0 = ''

function! s:AfterQuery(pat, cmdname)
    let tmpfile = tempname()
    call s:SaveStrToFile(s:cscope_cmd_out, tmpfile)
    let casechar = s:grep_opt_name_icase_{s:grep_opt_icase}.s:grep_opt_name_whole_{s:grep_opt_whole}.s:grep_opt_name_recurse_{s:grep_opt_recurse}.s:grep_opt_name_regex_{s:grep_opt_regex}
    call s:InsertQuery(1, a:cmdname." ".casechar, a:pat, 0, tmpfile, s:grep_opt_dir)
    call s:GotoCodeWindow()
endfunction

function! s:DoGrep()
    silent call s:RunGrepSub()
    " call s:SaveOptions()
    if s:cscope_cmd_out == ""
        return
    endif
    call s:AfterQuery(s:grep_pattern, "grep")
endfunction

function! s:DoGrepFromOptionWin()
    exec "q!"
    redraw
    call s:DoGrep()
endfunction

function! s:GrepOptionWinTab()
    echo "tab" 
    " redraw
    " call s:DoGrep()
endfunction

function! s:GrepOptionToggleCase()
    let s:grep_opt_icase = 1 - s:grep_opt_icase 
    call s:UpdateGrepOptWin(7, s:grep_opt_icase)
endfunction

function! s:GrepOptionToggleWhole()
    let s:grep_opt_whole = 1 - s:grep_opt_whole 
    call s:UpdateGrepOptWin(21,s:grep_opt_whole)
endfunction

function! s:GrepOptionToggleReg()
    let s:grep_opt_regex = 1 - s:grep_opt_regex 
    call s:UpdateGrepOptWin(31,s:grep_opt_regex)
endfunction

function! s:GrepOptionToggleRec()
    let s:grep_opt_recurse = 1 - s:grep_opt_recurse 
    call s:UpdateGrepOptWin(44,s:grep_opt_recurse)
endfunction

function! s:ClickGrepOptionWin()
    let i = col(".") 
    "case[7] whole-word[ ] regexp[X] recursive[ ]       <<OK>>  <<Cancel>>
    "      8 10-        22 24-    32 34-       45       53- 58  61-     70 
    if (i<=8)
        call s:GrepOptionToggleCase()
    elseif (i>=10 && i<=22)
        call s:GrepOptionToggleWhole()
    elseif (i>=24 && i<=32)
        call s:GrepOptionToggleReg()
    elseif (i>=34 && i<=45)
        call s:GrepOptionToggleRec()
    elseif (i>=53 && i<=58)
        call s:DoGrepFromOptionWin()
    elseif (i>=61 && i<=70)
        exec "q!"
        redraw
        "call s:CloseGrepOptionWin()
        return
    endif
endfunction

function! s:InitGrepOptions()
    let winNum = s:FindWindow(s:CIDE_WIN_TITLE_GREPOPTIONS)
    if (winNum == -1)
        set noequalalways 
        call s:CreateWindow('botright 1new', s:CIDE_WIN_TITLE_GREPOPTIONS)
        let str = s:GetOptionStr()
        call append(0,str)
        exe "2d"
        exe 1
        resize 1
        redraw
        setlocal nomodifiable
        silent! setlocal buftype=nofile
        silent! setlocal bufhidden=delete
        silent! setlocal noswapfile
        silent! setlocal nowrap
        silent! setlocal nonumber
        silent! setlocal nobuflisted
        nnoremap <buffer> <silent> <CR> :call <SID>DoGrepFromOptionWin()<CR>
        nnoremap <buffer> <silent> <LeftMouse> <LeftMouse>:call <SID>ClickGrepOptionWin()<CR>
        nnoremap <buffer> <silent> c :call <SID>GrepOptionToggleCase()<CR>
        nnoremap <buffer> <silent> w :call <SID>GrepOptionToggleWhole()<CR>
        nnoremap <buffer> <silent> r :call <SID>GrepOptionToggleRec()<CR>
        nnoremap <buffer> <silent> e :call <SID>GrepOptionToggleReg()<CR>
        nnoremap <buffer> <silent> <TAB> :call <SID>GrepOptionWinTab()<CR>
        if has('syntax')
            syntax match OptionName '\s\+\zs\S\+\ze\[' contains=OptionKey
            syntax match ButtonName '<<\zs\S\+\ze>>'
            syntax match OptionKey '[CWER]' contained
            if has('gui_running') || &t_Co > 2
                highlight OptionKey  cterm=underline gui=underline
                highlight OptionName guifg=#00FF00
                highlight ButtonName guifg=#FFFF00
            endif
        endif
        exec "normal 55|"
    endif
endfunction

function! s:CideLoadOptions()
    " Only to be loaded once
    if strlen(s:cide_cur_cfg_path) < 3
        " try find a config file along the parent folders
        let cide_cfg_path = s:FindFileInParentFolders(s:CIDE_CFG_FNAME)
        if strlen(cide_cfg_path) > 3
            " config file found for the first time
            let s:cide_cur_cfg_path = cide_cfg_path
            let oldpath = s:ChangeDirectory(cide_cfg_path) " save original directory
            exe "source " . s:CIDE_CFG_FNAME
            call s:ChangeDirectory(oldpath) " restore original directory
        endif
    endif
endfunction

function! s:CideSaveOptions()
    if strlen(s:cide_cur_cfg_path) > 3
        let oldpath = s:ChangeDirectory(s:cide_cur_cfg_path) " save original directory
        let outstr = ""
        let outstr = outstr . "let s:grep_opt_dir = '" . s:grep_opt_dir . "'\n"
        let outstr = outstr . "let s:grep_opt_files = '". s:grep_opt_files . "'\n"
        let outstr = outstr . "let s:grep_opt_whole = ". s:grep_opt_whole . "\n"
        let outstr = outstr . "let s:grep_opt_icase = ". s:grep_opt_icase . "\n"
        let outstr = outstr . "let s:grep_opt_recurse = ". s:grep_opt_recurse . "\n"
        let outstr = outstr . "let s:grep_opt_regex = ". s:grep_opt_regex . "\n"
        call s:SaveStrToFile(outstr, s:CIDE_CFG_FNAME)
        call s:ChangeDirectory(oldpath) " restore original directory
    endif
endfunction

function! FileTypeCompletion(ArgLead, CmdLine, CursorPos)
    return s:cide_grep_filespecs
endfunction

function! s:RunGrep()
    call s:CideLoadOptions()

    " Get the identifier and file list from user
    let grep_pattern0 = input("Search for pattern: ", expand("<cword>"))
    if grep_pattern0 == ""
        return
    endif
    let s:grep_pattern = grep_pattern0

    let grep_files0 = input("Search in files: ", s:grep_opt_files, "customlist,FileTypeCompletion")
    if grep_files0 == ""
        return
    endif
    let s:grep_opt_files = grep_files0

    let grep_dir0 = input("Search under folder: ", s:grep_opt_dir, "dir")
    if grep_dir0 == ""
        return
    endif
    if !isdirectory(grep_dir0)
        call s:MsgError('invalid directory "'.grep_dir0.'"')
        return
    end
    let s:grep_opt_dir = grep_dir0
    let s:grep_repby = ""

    call s:InitGrepOptions()
    return
endfunction

function! s:RunGrepLast()
    call s:CideLoadOptions()
    " Get the identifier and file list from user
    let grep_pattern0 = expand("<cword>")
    if grep_pattern0 == ""
        return
    endif
    let s:grep_pattern = grep_pattern0
    let s:grep_repby = ""
    call s:DoGrep()
    return
endfunction

function! s:CB_ShellCommanderOpenWin()
    let reswin = s:GotoWindowByName(s:CIDE_WIN_TITLE_SHELL_OUT)
    if (reswin == -1) 
        let ww = winwidth(0) * 80/100
        call s:CreateWindow('bo '.ww.'vnew', s:CIDE_WIN_TITLE_SHELL_OUT)
        let reswin = s:GotoWindowByName(s:CIDE_WIN_TITLE_SHELL_OUT)
        if (reswin == -1) 
            return
        end
    endif
    :$
endfunction

function! s:CB_ShellCommanderExec()
    let idx = line('.')
    if (idx < 1)
        return
    endif
    redir => message
    let line_text = getline(idx)

    silent! echo "\n======================== ".system(s:cide_shell_date)."$ " line_text
    silent! echo system(substitute(line_text, "\s*#.*", "", "g"))
    redir END

    call s:CB_ShellCommanderOpenWin()
    silent put=message
endfunction

" Initializes the query list window
function! s:ShellCommander()
    "  setlocal nomodifiable
    "  nnoremap <2-LeftMouse> :echo(system(getline('.')))<CR>
    nnoremap <buffer> <silent> <2-LeftMouse> :call <SID>CB_ShellCommanderExec()<CR>
    set nowrap
    call s:CB_ShellCommanderOpenWin()
endfunction

function! s:SaveBackup()
    let curfname = expand("%:p")
    let timestp = strftime("%Y-%m-%d-%T",getftime(curfname)).".bak"
    let timestp = substitute(timestp,":","-","g") 
    let bakfname = curfname.".".timestp
    echom bakfname
    "   return
    silent! exec "!copy \"".curfname."\" \"".bakfname."\""
    exec "w"
endfunction

function! s:MyMake(makecmd)
    set makeprg=make\ clean\ all\ -f\ mk-build.mak\ $*\ 2>&1\ \\\|\ tee\ build.log
    exec "make ".a:makecmd
    cope
endfunction

" Define set of make commands
command! -nargs=* Imake                     call <SID>MyMake("")
command! -nargs=* Imakeclean                call <SID>MyMake("clean")
command! -nargs=* Imakerebuild              call <SID>MyMake("clean all")

" Define set of cide commands
command! -nargs=* Igrep                     call s:RunGrep()
command! -nargs=* Ilast                     call s:RunGrepLast()
command! -nargs=* Isymb                     call <SID>RunCscope(0,"") " c symbol
command! -nargs=* Idefi                     call <SID>RunCscope(1,"") " global definition
command! -nargs=* Icall                     call <SID>RunCscope(2,"") " calling
command! -nargs=* Icaby                     call <SID>RunCscope(3,"") " called by
command! -nargs=* Ifind                     call <SID>RunCscope(6,"") " cscope find egrep
command! -nargs=* Ifile                     call <SID>RunCscope(7,"") " find this file
command! -nargs=* Iincl                     call <SID>RunCscope(8,"") " find file including this file
command! -nargs=* CscopeCase                call <SID>CscopeCase(<f-args>)
command! -nargs=* MyUniqueNames             call <SID>UniqueNames(<f-args>)
command! -nargs=* Loadhist                  call <SID>LoadHist(0)
command! -nargs=* CscopeRebuild             call <SID>CscopeRebuild()
command! -nargs=* Appendhist                call <SID>LoadHist(1)
command! -nargs=* Savehist                  call <SID>SaveHist()
command! -nargs=* CideToggle                call <SID>CideToggle()
command! -nargs=* CideSaveOptions           call <SID>CideSaveOptions()
command! -nargs=* Icalleetree               call <SID>NewSymbol(0)
command! -nargs=* Icallertree               call <SID>NewSymbol(1)
command! -nargs=* GetDef                    call <SID>GetDef()
command! -nargs=* ExpandTree                call <SID>ExpandTree()
command! -nargs=* ToggleFold                call <SID>ToggleFold()
command! -nargs=* DeleteSubtree             call <SID>DeleteSubtree()
command! -nargs=* DeleteUnder               call <SID>DeleteUnder()
command! -nargs=* ClearRedundant            call <SID>ClearRedundant()
command! -nargs=* SaveBackup                call <SID>SaveBackup()
command! -nargs=* MyTest    silent!         call <SID>ExecVimCmdOutput("cs show")
command! -nargs=* ShellCommander            call <SID>ShellCommander()

" Define short cuts
nmap <Leader>s  :Isymb<CR>
nmap <Leader>d  :Idefi<CR>
nmap <Leader>c  :Icall<CR>
nmap <Leader>b  :Icaby<CR>
nmap <Leader>f  :Ifile<CR>
nmap <Leader>i  :Iincl<CR>
nmap <Leader>l  :Ilast<CR>
nmap <Leader>g  :Igrep<CR>
nmap <Leader>r  :Icallertree<CR>
nmap <Leader>e  :Icalleetree<CR>

" Define menu items under CIDE
:menu <silent> &CIDE.-SepSearch-            :
:menu <silent> &CIDE.&Symbol<TAB>s          :Isymb<CR>
:menu <silent> &CIDE.global&Def<TAB>d       :Idefi<CR>
:menu <silent> &CIDE.&Calls<TAB>c           :Icall<CR>
:menu <silent> &CIDE.called&By<TAB>b        :Icaby<CR>
:menu <silent> &CIDE.&Grep<TAB>g            :Igrep<CR>
:menu <silent> &CIDE.grep&Last<TAB>l        :Ilast<CR>
:menu <silent> &CIDE.this&File<TAB>f        :Ifile<CR>
:menu <silent> &CIDE.&Include<TAB>i         :Iincl<CR>
:menu <silent> &CIDE.-SepManage-            :
:menu <silent> &CIDE.CideHistory.&Load<TAB>l   :Loadhist<CR>
:menu <silent> &CIDE.CideHistory.&Append<TAB>a :Appendhist<CR>
:menu <silent> &CIDE.CideHistory.&Save<TAB>s   :Savehist<CR>
:menu <silent> &CIDE.CideToggle             :CideToggle<CR>
:menu <silent> &CIDE.CideSaveOption         :CideSaveOptions<CR>
:menu <silent> &CIDE.CscopeRebuild          :CscopeRebuild<CR>
:menu <silent> &CIDE.CscopeCase             :CscopeCase<CR>
:menu <silent> &CIDE.Save+Backup            :SaveBackup<CR>
:menu <silent> &CIDE.Shell\ Commander       :ShellCommander<CR>

" Define menu items under CodeTree
:menu <silent> &CIDE.-SepCodeTree-          :
:menu <silent> &CIDE.CTCallee               :Icalleetree<CR>
:menu <silent> &CIDE.CTCaller               :Icallertree<CR>
:menu <silent> &CIDE.CTGetDef               :GetDef<CR>
:menu <silent> &CIDE.CTExpand               :ExpandTree<CR>
:menu <silent> &CIDE.CTToggleFold           :ToggleFold<CR>
:menu <silent> &CIDE.CTDeleteSubtree        :DeleteSubtree<CR>
:menu <silent> &CIDE.CTDeleteUnder          :DeleteUnder<CR>
:menu <silent> &CIDE.CTUniqueName           :MyUniqueNames<CR>
:menu <silent> &CIDE.-SepVersion-          :
:menu <silent> &CIDE.version\ 0\.8          :

" restore 'cpo'
let &cpo = s:cpo_save
unlet s:cpo_save

