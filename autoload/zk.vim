function! zk#is_zk_proj()
    return finddir('.zk') != ''
endfunction

function! zk#index()
    if !exists('s:zk_index_job')
        let s:zk_index_job = job_start('zk index')
    endif

    if job_status(s:zk_index_job) != 'run'
        unlet s:zk_index_job
    endif
endfunction

function! zk#cache_omnicompl()
    if !exists('b:zk_omnicompl_links_cache_job')
        let cmd = 'zk list'
                    \ . ' --format "{{link}}"'
                    \ . ' --working-dir ' . expand('%:p:h')
        let b:zk_omnicompl_links_cache_job = job_start(cmd,
                    \ {'close_cb': 's:omnicompl_cache_job_close_cb'})
    endif

    if job_status(b:zk_omnicompl_links_cache_job) != 'run'
        unlet b:zk_omnicompl_links_cache_job
    endif
endfunction

function! s:omnicompl_cache_job_close_cb(channel) abort
    let omnicompl_links = []
    while ch_status(a:channel, {'part': 'out'}) == 'buffered'
        let omnicompl_links += [ ch_read(a:channel) ]
    endwhile
    let b:zk_omnicompl_links = omnicompl_links
endfunction

function! zk#omnicomplete(findstart, base)
    if a:findstart
        return s:omnicomplete_find_start()
    endif

    let results = []
    if b:zk_omnicompl_context ==# 'link' && exists('b:zk_omnicompl_links')
        let results = b:zk_omnicompl_links
    endif

    return matchfuzzy(results, a:base)
endfunction

function! s:omnicomplete_find_start()
    let l:lnum = line('.')
    let l:line = getline('.')
    let b:zk_omnicompl_context = ''

    if l:line =~# '^.*\[[^\[\]]*$'
        let b:zk_omnicompl_context = 'link'
        return matchend(l:line, '^.*\[') - 1
    endif

    return -1
endfunction
