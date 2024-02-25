if !zk#is_zk_proj()
    finish
endif

if get(g:, 'zk_enable_omnicompl', 0)
    setlocal omnifunc=zk#omnicomplete
    autocmd CursorHold <buffer> call zk#cache_omnicompl()
endif

autocmd CursorHold <buffer> call zk#index()
