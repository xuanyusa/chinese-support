function! chinese_support#_log(prefix, msg, filename, enable)
    if a:enable
        redir => output
        let message = a:msg
        if type(message) != v:t_string
            let message = string(message)
        endif
        silent echomsg a:prefix .. ' ' .. message
        redir END
        call writefile([output], a:filename, 'a')
    endif
endfunction

function! chinese_support#log(msg)
    call chinese_support#_log('chinese_support', a:msg, g:chinese_support_logfile, g:chinese_support_debug)
endfunction


function! chinese_support#_echohl(hl, msg)
    if empty(a:msg) | return | endif
    execute 'echohl '.. a:hl
    echo ''
    redraw
    echomsg a:msg
    echohl None
endfunction

function! chinese_support#echohl(msg)
    call chinese_support#_echohl('ErrorMsg', a:msg)
endfunction
