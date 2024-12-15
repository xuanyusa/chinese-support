" Vim global plugin for chinese support
" Author:   xuanyusa <xuanyusa@yeah.net>
" Source:   https://github.com/xuanyusa/vim-chinese-support
" Last Change:    2024-12-15
" License:  MIT

if exists('g:chinese_support_loaded')
    finish
endif
let g:chinese_support_loaded = 1

let s:cpo_save = &cpo
set cpo&vim

let g:chinese_support_debug = 0
let g:chinese_support_logfile = 'chinese_support.log'

let s:szm_meta_regexp = '([aoebpmfdtnlgkhjqxryw]|zh?|ch?|sh?)'
let s:pinyin_meta_regexp = '(a[ino]?|ang|bang|ba[ino]?|beng|be[in]?|bing|bia[no]?|bi[en]?|bu|cang|ca[ino]?|ceng|ce[in]?|chang|cha[ino]?|cheng|che[n]?|chi|chong|chou|chuang|chua[in]|chu[ino]?|ci|cong|cou|cuan|cu[ino]?|dang|da[ino]?|deng|de[in]?|dia[no]?|ding|di[ae]?|dong|dou|duan|du[ino]?|fang|fan|fa|feng|fe[in]{1}|fo[u]?|fu|gang|ga[ino]?|geng|ge[in]?|gong|gou|guang|gua[in]?|gu[ino]?|hang|ha[ino]?|heng|he[in]?|hong|hou|huang|hua[in]?|hu[ino]?|jiang|jia[no]?|jiong|ji[nu]?|juan|ju[en]?|kang|ka[ino]?|keng|ke[n]?|kong|kou|kuang|kua[in]?|ku[ino]?|lang|la[ino]?|leng|le[i]?|liang|lia[no]?|ling|li[enu]?|long|lou|luan|lu[no]?|lv[e]?|mang|ma[ino]?|meng|me[in]?|mia[no]?|ming|mi[nu]?|mo[u]?|mu|nang|na[ino]?|neng|ne[in]?|niang|nia[no]?|ning|ni[enu]?|nong|nou|nuan|nu[on]?|nv[e]?|pang|pa[ino]?|pa|peng|pe[in]?|ping|pia[no]?|pi[en]?|po[u]?|pu|qiang|qia[no]?|qiong|qing|qi[aenu]?|quan|qu[en]?|rang|ra[no]{1}|reng|re[n]?|rong|rou|ri|ruan|ru[ino]?|sang|sa[ino]?|seng|se[n]?|shang|sha[ino]?|sheng|she[in]?|shi|shou|shuang|shua[in]?|shu[ino]?|si|song|sou|suan|su[ino]?|tang|ta[ino]?|teng|te|ting|ti[e]?|tia[no]?|tong|tou|tuan|tu[ino]?|wang|wa[ni]?|weng|we[in]{1}|w[ou]{1}|xiang|xia[no]?|xiong|xing|xi[enu]?|xuan|xu[en]|yang|ya[no]?|ye|ying|yi[n]?|yong|you|yo|yuan|yu[en]?|zang|za[ino]?|zeng|ze[in]?|zhang|zha[ino]?|zheng|zhe[in]?|zhi|zhong|zhou|zhuang|zhua[in]?|zhu[ino]?|zi|zong|zou|zuan|zu[ino]?)'
let s:pinyin_regexp = s:pinyin_meta_regexp .. '|' .. s:szm_meta_regexp 
let s:pinyin_regexp_full = '\v\c^(' .. s:pinyin_regexp .. ")('?" .. s:pinyin_regexp .. ")*$"
let s:dict = {}
let s:dict_name = expand('<sfile>:p:h') .. '/chinese.dict'
function LoadDict()
    if !empty(s:dict)
        return
    endif
    for line in readfile(s:dict_name)
        let [chinese, pinyin] = split(line) 
        let s:dict[chinese] = pinyin
    endfor
endfunction
call LoadDict()

let s:delimiter = ','
let s:matches = []
let s:loc = []
" 是否使用了中文搜索
let s:chinese_search = 0
" 最后一次使用的搜索模式
let s:last_pattern = ''
" 最后一次使用的搜索方向1正向，0反向
let s:last_direction = 1
" 最后一次搜索是否碰到缓冲区的顶部或底部
let s:last_hit_top_bottom = 0
" 最后一次搜索的目标中文长度
let s:last_len = 0

function! ClearSearchResult()
    if !empty(s:matches)
        for id in s:matches
            call matchdelete(id)
        endfor
        call remove(s:matches, 0, len(s:matches) - 1)
    endif
    if !empty(s:loc)
        call remove(s:loc, 0, len(s:loc) - 1)
    endif
endfunction

function! SearchChinese(pattern, len, direction, remember_direction)
    call ClearSearchResult()
    if a:remember_direction
        let s:last_direction = a:direction
    endif
    let start_line_num = getcurpos()[1]
    let reach_start_times = 0
    while v:true
        let [hit_top_bottom, reach_start] =  FindMatches(a:pattern, a:len, start_line_num, a:direction)
        if reach_start
            let reach_start_times += 1
        endif
        if reach_start_times >= 2 && empty(s:loc)
            return 0
        endif
        if !empty(s:loc)
            call sort(s:loc, "MyLocSort")
            let s:chinese_search = 1
            let s:last_pattern = a:pattern
            let s:last_len = a:len
            let move = MoveCursor2Next(s:loc, a:direction)
            if move
                let match_id = matchaddpos('Search', s:loc->mapnew({_,v->v[0:2]}))
                call add(s:matches, match_id)
                call chinese_support#log(s:matches) 
                call chinese_support#log(s:loc) 
                return 1
            elseif GotoNextPage(hit_top_bottom, a:direction)
                call ClearSearchResult()
                continue
            else
                return 0
            endif
        elseif hit_top_bottom
            if !GotoNextPageWhenHitEdge(a:direction)
                return 0
            endif
        else
            call GotoNextPageWhenNotHitEdge(a:direction)
        endif
    endwhile
endfunction

function! GotoNextPageWhenNotHitEdge(direction)
    if a:direction
        execute "normal! \<c-f>0"
    else 
        execute "normal! \<c-b>$"
    endif
    return 1
endfunction

function! GotoNextPageWhenHitEdge(direction)
    if &wrapscan
        if a:direction
            execute 'normal! gg0'
        else
            execute 'normal! G$'
        endif
        return 1
    else 
        return 0	
    endif
endfunction

function! GotoNextPage(hit_top_bottom, direction)
    if a:hit_top_bottom
        return GotoNextPageWhenHitEdge(a:direction)
    else
        return GotoNextPageWhenNotHitEdge(a:direction)
    endif   
endfunction

function! FindMatches(pattern, len, start_line_num, direction)
    let hit_top_bottom = 0
    let reach_start = 0
    let w0_lnum = line('w0')
    let win_end_lnum = line('w$')
    call chinese_support#log('当前窗口行范围 ' .. string([w0_lnum, win_end_lnum]))
    let lines = getline(w0_lnum, win_end_lnum)
    if a:direction == 1 && win_end_lnum == line('$')
        let hit_top_bottom = 1		
    elseif a:direction == 0 && w0_lnum == 1
        let hit_top_bottom = 1
    endif
    let s:last_hit_top_bottom = hit_top_bottom
    if a:start_line_num >= w0_lnum && a:start_line_num <= win_end_lnum
        let reach_start = 1
    endif
    let pinyin_lines = Translate(lines)
    let lidx = 0
    for pl in pinyin_lines
        let m = match(pl, a:pattern)
        if m < 0
            let lidx += 1
            continue
        endif
        let lnum = w0_lnum + lidx
        let l = getline(lnum)
        while m >= 0
            let str = strpart(pl, 0, m+1+1)
            let char_idx = count(str, s:delimiter) - 1
            " let c = nr2char(strgetchar(str, char_idx)
            let chars = strcharpart(l, char_idx, a:len)
            if !IsChineseForChars(chars)
                let m = match(pl, a:pattern, m + 1)
                continue
            endif
            let char_bytes = chars->strlen()
            let col = byteidx(l, char_idx) + 1
            let target = [lnum, col, char_bytes, chars]
            if s:loc->index(target) < 0
                call add(s:loc, target)
            endif
            let m = match(pl, a:pattern, m + 1)
        endwhile
        let lidx += 1
    endfor
    return [hit_top_bottom, reach_start]
endfunction

function MyLocSort(a,b)
    if a:a[0] == a:b[0]
        return a:a[1] - a:b[1]
    endif
    return a:a[0] - a:b[0]
endfunction

function! MoveCursor2Next(match_pos_list, direction)
    let cur_cursor = getcurpos()
    call chinese_support#log('当前光标位置 ' .. string(cur_cursor[1:2]) )
    call chinese_support#log('当前匹配位置列表 ' .. string(a:match_pos_list))
    let list = a:match_pos_list
    let op = '<'
    if a:direction
        let op = '>'
    else
        let list = a:match_pos_list->copy()->reverse()
    endif
    let idx = list->indexof('(v:val[0]==cur_cursor[1] && v:val[1] ' .. op .. ' cur_cursor[2]) || v:val[0] ' .. op .. 'cur_cursor[1]')
    if idx < 0 || idx >= len(s:loc)
        return 0
    endif
    call cursor(list[idx][:1])
    call chinese_support#log('移动后光标位置' .. string(getcurpos()[1:2]))
    return 1
endfunction

" function! IsChinese(chars)
"     return a:chars =~ '\v^[\u4e00-\u9fff]+$'
" endfunction

function! IsChineseForChar(char)
    let nr = char2nr(a:char)
    if nr >= 0x4e00 && nr <= 0x9fff
        return 1
    endif
    return 0
endfunction

function! IsChineseForChars(chars)
    for c in a:chars
        if !IsChineseForChar(c)
            return 0
        endif
    endfor 
    return 1
endfunction

function! Translate(lines)
    let pinyin_lines = []
    for l in a:lines
        if empty(l)
            call add(pinyin_lines, l)
            continue
        endif
        let result_list = []
        for c in l
            if has_key(s:dict, c)
                call add(result_list, s:dict[c])
            elseif c ==# ','
                call add(result_list, '')
            else
                call add(result_list, c)
            endif
        endfor
        let pinyin_line = s:delimiter .. join(result_list, s:delimiter)
        call add(pinyin_lines, pinyin_line)
    endfor 
    call chinese_support#log(pinyin_lines) 
    return pinyin_lines
endfunction

function! SplitPinYin(pinyin)
    " let p = '\v[^aoeiuv]?h?[iuv]?(ai|ei|ao|ou|er|ang?|eng?|ong|a|o|e|i|u|ng|n)?'
    let p = "\\v^'?" .. s:pinyin_regexp
    let py = a:pinyin
    let m = matchstrpos(py, p)
    let r = []
    while !empty(m[0]) && m[1] == 0
        let py = strpart(py, len(m[0]))
        if m[0]->strpart(0, 1) ==# "'"
            let m[0] = strpart(m[0], 1)
        endif
        let r += [m[0]]
        let m = matchstrpos(py, p)
    endwhile
    if !empty(py)
        call remove(r, 0, len(r) - 1)
    endif
    call chinese_support#log('拼音拆分结果 ' .. string(r)) 
    return r
endfunction

function! s:MySearch(direction)
    let s:last_pattern = @/
    let @/=''
    nohls
    let wv_origin = winsaveview()
    let prompt = '?'
    if a:direction
        let prompt = '/'
    endif
    let input = input(prompt)
    if input !~# s:pinyin_regexp_full
        call chinese_support#echohl('无效的拼音' .. input)
        return
    endif
    let pinyin_list = SplitPinYin(input)
    if empty(pinyin_list)
        call chinese_support#echohl('无效的拼音' .. input)
        return
    endif
    " case insensitive
    let pattern = '\v\c'
    let len = pinyin_list->len()
    for e in pinyin_list
        if e =~ '\v\c^' .. s:szm_meta_regexp .. '$'
            let pattern = pattern .. s:delimiter .. '([^,]{-1,};)?' .. e .. '[^,]{-}'
        else
            let pattern = pattern .. s:delimiter .. '([^,]{-1,};)?' .. e .. '(;[^,;]{-1,})?'
        endif
    endfor
    call chinese_support#log('待查找的正则 -> ' .. pattern) 
    let hit =  SearchChinese(pattern, len, a:direction, 1)
    if !hit
        let @/=s:last_pattern
        call chinese_support#echohl('没有找到匹配' .. input .. '的中文')
        call winrestview(wv_origin)
    endif
endfunction

if !hasmapto('<Plug>chinese-support-search-forward;')
    nnoremap <leader>/ <Plug>chinese-support-search-forward;
endif
if !hasmapto('<Plug>chinese-support-search-backward;')
    nnoremap <leader>? <Plug>chinese-support-search-backward;
endif

nnoremap <script><unique> <Plug>chinese-support-search-forward; :call <SID>MySearch(1)<CR>
nnoremap <script><unique> <Plug>chinese-support-search-backward; :call <SID>MySearch(0)<CR>

augroup ChineseSupportSearch
    autocmd!
    autocmd CmdlineLeave / call ClearSetup()
    autocmd CmdlineLeave : call ClearMatchesHighlight()
augroup END

function! ClearSetup()
    call chinese_support#log('命令行类型 -> ' .. getcmdtype()) 
    let s:chinese_search = 0    
    call ClearSearchResult()
endfunction

function! ClearMatchesHighlight()
    let cmdline = getcmdline()
    call chinese_support#log('命令行内容 -> ' .. cmdline) 
    let fullcmdline = fullcommand(cmdline)
    call chinese_support#log('完整命令行内容 -> ' .. fullcmdline) 
    if fullcmdline == 'nohlsearch' && !empty(s:matches)
        for id in s:matches
            call matchdelete(id)
        endfor 
        call remove(s:matches, 0, len(s:matches) - 1)
    endif
endfunction

nnoremap <silent> n :silent call DoAfternN('n')<CR>
nnoremap <silent> N :silent call DoAfternN('N')<CR>
nnoremap <silent> * :silent call ClearSetup()<CR>*
nnoremap <silent> # :silent call ClearSetup()<CR>#
nnoremap <silent> g* :silent call ClearSetup()<CR>g*
nnoremap <silent> g# :silent call ClearSetup()<CR>g#

function! DoAfternN(command)
    call chinese_support#log(a:command .. " command executed") 
    if !s:chinese_search
        execute "normal! " .. a:command
        return
    endif
    call chinese_support#log("执行中文模式的" .. a:command) 
    let wv_origin = winsaveview()
    let direction = s:last_direction
    if a:command ==# 'N'
        let direction = s:last_direction == 1 ? 0 : 1
    endif
    let move = MoveCursor2Next(s:loc, direction)
    if move
        return
    elseif GotoNextPage(s:last_hit_top_bottom, direction)
        let hit =  SearchChinese(s:last_pattern,s:last_len, direction, 0)
        if !hit
            call chinese_support#log('没有找到匹配' .. s:last_pattern .. '的中文') 
            call winrestview(wv_origin)
        endif
    else
        return
    endif
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save
