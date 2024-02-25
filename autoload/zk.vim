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
                    \ {'close_cb': 's:omnicompl_links_cache_job_close_cb'})
    endif

    if job_status(b:zk_omnicompl_links_cache_job) != 'run'
        unlet b:zk_omnicompl_links_cache_job
    endif

    if !exists('b:zk_omnicompl_tags_cache_job')
        let cmd = 'zk tag list'
                    \ . ' --format name'
                    \ . ' --no-pager'
                    \ . ' --quiet'
        let b:zk_omnicompl_tags_cache_job = job_start(cmd,
                    \ {'close_cb': 's:omnicompl_tags_cache_job_close_cb'})
    endif

    if job_status(b:zk_omnicompl_tags_cache_job) != 'run'
        unlet b:zk_omnicompl_tags_cache_job
    endif
endfunction

function! s:omnicompl_links_cache_job_close_cb(channel) abort
    let omnicompl_links = []
    while ch_status(a:channel, {'part': 'out'}) == 'buffered'
        let omnicompl_links += [ ch_read(a:channel) ]
    endwhile
    let b:zk_omnicompl_links = omnicompl_links
endfunction

function! s:omnicompl_tags_cache_job_close_cb(channel) abort
    let omnicompl_tags = []
    while ch_status(a:channel, {'part': 'out'}) == 'buffered'
        let omnicompl_tags += [ ch_read(a:channel) ]
    endwhile
    let b:zk_omnicompl_tags = omnicompl_tags
endfunction

function! zk#omnicomplete(findstart, base)
    if a:findstart
        return s:omnicomplete_find_start()
    endif

    let results = []
    if b:zk_omnicompl_context ==# 'link' && exists('b:zk_omnicompl_links')
        let results = b:zk_omnicompl_links
    endif

    if b:zk_omnicompl_context ==# 'tag' && exists('b:zk_omnicompl_tags')
        let results = b:zk_omnicompl_tags
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

    if l:line =~# '^\(.*\s\)*\#\S*$'
        let b:zk_omnicompl_context = 'tag'
        return matchend(l:line, '^\(.*\s\)*\#')
    endif

    return -1
endfunction
