local ass = {}

local util = require'ass.util'

vim.cmd("py3 import ass")

function ass.setup(opts)
    opts = opts or {}

    vim.cmd[[
        function! AssPlayComp(ArgLead, CmdLine, CursorPos)
            return ['line', 'all', 'begin', 'end', 'before', 'after']
        endfunction

        command -nargs=1 -complete=file AssSplit lua require'ass.split'.open_ass("<args>")
        command -nargs=1 -complete=file AssSplitSelf lua require'ass.split'.open()
        command AssReplace lua require'ass.split'.replace()
        command -count=1 AssReplaceMove lua require'ass.split'.replace_move(<count>)
        command -count=1 AssAppend lua require'ass.split'.append(<count>)
        command -count=1 AssSplitUp lua require'ass.split'.cursor_up(<count>)
        command -count=1 AssSplitDown lua require'ass.split'.cursor_down(<count>)
        command -count=1 AssJoin lua require'ass'.join_cursor(<count>)
        command -range=1 AssJoinRange lua require'ass'.join(<line1> - 1, <line2> - 1)
        command -range=1 AssShow lua require'ass'.show()
        command -nargs=1 -complete=customlist,AssPlayComp AssPlay lua require'ass'.play_line("<args>", false)
        command -nargs=1 -complete=customlist,AssPlayComp AssPlayBG lua require'ass'.play_line("<args>", true)
    ]]

    if opts.conceal == true then
        vim.cmd[[
            autocmd FileType ass lua require'ass'.setup_conceal()
        ]]
    end

    if opts.remap_keys then
        vim.cmd[[
            autocmd FileType ass nnoremap-local <BS> <Cmd>AssReplace<CR>
            autocmd FileType ass nnoremap-local <expr> <CR> '<Cmd>AssReplaceMove' . v:count1 . '<CR>'
            autocmd FileType ass nnoremap-local <expr> <Tab> '<Cmd>AssAppend' . v:count1 . '<CR>'
            autocmd FileType ass nnoremap-local <expr> <M-k> '<Cmd>AssSplitUp' . v:count1 . '<CR>'
            autocmd FileType ass nnoremap-local <expr> <M-j> '<Cmd>AssSplitDown' . v:count1 . '<CR>'
            autocmd FileType ass nnoremap-local <expr> <C-k> 'k<Cmd>AssSplitDown' . v:count1 . '<CR>'
            autocmd FileType ass nnoremap-local <expr> <C-j> 'j<Cmd>AssSplitUp' . v:count1 . '<CR>'
            autocmd FileType ass nnoremap-local <expr> J '<Cmd>AssJoin' . v:count1 . '<CR>'
            autocmd FileType ass nnoremap-local <leader>av <Cmd>AssShow<CR>
            autocmd FileType ass nnoremap-local <leader>as <Cmd>AssPlay line<CR>
            autocmd FileType ass nnoremap-local <leader>at <Cmd>AssPlay all<CR>
            autocmd FileType ass nnoremap-local <leader>ae <Cmd>AssPlayBG begin<CR>
            autocmd FileType ass nnoremap-local <leader>ad <Cmd>AssPlayBG end<CR>
            autocmd FileType ass nnoremap-local <leader>aq <Cmd>AssPlayBG before<CR>
            autocmd FileType ass nnoremap-local <leader>aw <Cmd>AssPlayBG after<CR>
            autocmd FileType ass vnoremap-local J :AssJoinRange<CR>
            autocmd FileType ass nnoremap-local _ 09f,l
        ]]
    end
end

function ass.join_cursor(count)
    local win = vim.api.nvim_get_current_win()
    local c = vim.api.nvim_win_get_cursor(win)
    ass.join(c[1] - 1, c[1] + count - 1)
end

function ass.show()
    local line = util.escape_py(util.get_current_line(vim.api.nvim_get_current_win()))
    local res = vim.fn.py3eval(string.format('ass.get_show_cmd("%s")', line))
    if res ~= nil then
        vim.cmd("w !" .. res)
    end
end

function ass.play_line(opt, background)
    local line = util.escape_py(util.get_current_line(vim.api.nvim_get_current_win()))
    local res = vim.fn.py3eval(string.format('ass.get_play_cmd("%s", "%s", %s)', line, opt, background and "True" or "False"))
    if res ~= nil and res ~= vim.NIL then
        vim.cmd("!" .. res)
        vim.fn.feedkeys("<CR>")     -- close the "Enter" prompt
    end
end

function ass.join(from, to)
    local buf = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(buf, from, to + 1, false)

    local pythonlist = ""
    for _, k in ipairs(lines) do
        pythonlist = pythonlist .. string.format('"%s",', util.escape_py(k))
    end

    local res = vim.fn.py3eval(string.format('ass.join_lines([%s])', pythonlist))
    if res ~= nil and res ~= vim.NIL then
        vim.api.nvim_buf_set_lines(buf, from, to + 1, false, {res})
    end
end

function ass.setup_conceal()
    vim.cmd[[
        set conceallevel=2
        set concealcursor=n
    ]]
end

return ass
