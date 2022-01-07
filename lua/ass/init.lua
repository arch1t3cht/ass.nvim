local ass = {
    opts = {},
}

local util = require'ass.util'

function ass.get_line_dialogue(line)
    local res = util.pyeval(string.format('ass.get_line_dialogue("%s")', util.escape_py(line)))
    if res == vim.NIL then res = nil end
    return res
end

function ass.set_line_dialogue(line, diag)
    local res = util.pyeval(string.format('ass.set_line_dialogue("%s", "%s")', util.escape_py(line), util.escape_py(diag)))
    if res == vim.NIL then res = nil end
    return res
end

function ass.default_line_filter(line, oldline)
    return line
end

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
        command -count=1 AssLineSplit lua require'ass'.split_line()
        command -count=1 AssJoin lua require'ass'.join_cursor(<count>)
        command -range=1 AssJoinRange lua require'ass'.join(<line1> - 1, <line2> - 1)
        command -count=1 AssFilter lua require'ass'.filter_lines_cursor(<count>, nil)
        command -range=1 AssFilterRange lua require'ass'.filter_lines(<line1> - 1, <line2> - 1, nil)
        command -range=1 AssShow lua require'ass'.show()
        command -nargs=1 -complete=customlist,AssPlayComp AssPlay lua require'ass'.play_line("<args>", false)
        command -nargs=1 -complete=customlist,AssPlayComp AssPlayBG lua require'ass'.play_line("<args>", true)
    ]]

    if opts.conceal == true then
        vim.cmd[[
            autocmd FileType ass lua require'ass'.setup_conceal()
        ]]
    end

    if opts.mappings == true then
        vim.cmd[[
            autocmd FileType ass nnoremap <buffer> <leader>av <Cmd>AssShow<CR>
            autocmd FileType ass nnoremap <buffer> <leader>as <Cmd>AssPlay line<CR>
            autocmd FileType ass nnoremap <buffer> <leader>at <Cmd>AssPlay all<CR>
            autocmd FileType ass nnoremap <buffer> <leader>ae <Cmd>AssPlayBG begin<CR>
            autocmd FileType ass nnoremap <buffer> <leader>ad <Cmd>AssPlayBG end<CR>
            autocmd FileType ass nnoremap <buffer> <leader>aq <Cmd>AssPlayBG before<CR>
            autocmd FileType ass nnoremap <buffer> <leader>aw <Cmd>AssPlayBG after<CR>
            autocmd FileType ass nnoremap <buffer> <leader>ax <Cmd>AssLineSplit<CR>
            autocmd FileType ass nnoremap <buffer> <expr> <leader>af '<Cmd>AssFilter' . v:count1 . '<CR>'
            autocmd FileType ass vnoremap <buffer> <leader>af :AssFilterRange<CR>
            autocmd FileType ass nnoremap <buffer> <BS> <Cmd>AssReplace<CR><Cmd>AssSplitDown<CR>
            autocmd FileType ass nnoremap <buffer> <expr> <CR> '<Cmd>AssReplaceMove' . v:count1 . '<CR>'
            autocmd FileType ass nnoremap <buffer> <expr> <Tab> '<Cmd>AssAppend' . v:count1 . '<CR>'
            autocmd FileType ass nnoremap <buffer> <expr> <M-k> '<Cmd>AssSplitUp' . v:count1 . '<CR>'
            autocmd FileType ass nnoremap <buffer> <expr> <M-j> '<Cmd>AssSplitDown' . v:count1 . '<CR>'
            autocmd FileType ass nnoremap <buffer> <expr> <C-k> 'k<Cmd>AssSplitDown' . v:count1 . '<CR>'
            autocmd FileType ass nnoremap <buffer> <expr> <C-j> 'j<Cmd>AssSplitUp' . v:count1 . '<CR>'
            autocmd FileType ass nnoremap <buffer> <expr> <M-e> '<C-w>l' . v:count1 . '<C-e><C-w>h'
            autocmd FileType ass nnoremap <buffer> <expr> <M-y> '<C-w>l' . v:count1 . '<C-y><C-w>h'
            autocmd FileType ass nnoremap <buffer> <M-d> <C-w>l<C-d><C-w>h
            autocmd FileType ass nnoremap <buffer> <M-i> <C-w>l<C-u><C-w>h
        ]]
    end

    if opts.remap == true then
        vim.cmd[[
            autocmd FileType ass nnoremap <buffer> <expr> J '<Cmd>AssJoin' . v:count1 . '<CR>'
            autocmd FileType ass vnoremap <buffer> J :AssJoinRange<CR>
            autocmd FileType ass nnoremap <buffer> _ 09f,l
            autocmd FileType ass nnoremap <buffer> I 09f,a
        ]]
    end

    if not opts.line_hook then
        opts.line_hook = ass.default_line_filter
    end

    if opts.mpv_options_audio == nil then
        opts.mpv_options_audio = {"--no-video", "--no-config", "--really-quiet"}
    end

    if opts.mpv_options_video == nil then
        opts.mpv_options_video = {"--pause"}
    end

    ass.opts = opts
end

function ass.filter_lines_cursor(count, oldlines)
    local c = vim.api.nvim_win_get_cursor(0)
    ass.filter_lines(c[1] - 1, c[1] - 2 + count, oldlines)
end

function ass.filter_lines(from, to, oldlines)
    local buf = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(buf, from, to + 1, false)

    for k, v in ipairs(lines) do
        if oldlines ~= nil then
            lines[k] = ass.opts.line_hook(v, oldlines[k])
        else
            lines[k] = ass.opts.line_hook(v, nil)
        end
    end
    vim.api.nvim_buf_set_lines(buf, from, to + 1, false, lines)
end

function ass.python_init()
    vim.cmd("py3 import ass")
    vim.cmd(string.format("py3 ass.mpv_args_video = %s", util.python_list(ass.opts.mpv_options_video)))
    vim.cmd(string.format("py3 ass.mpv_args_audio = %s", util.python_list(ass.opts.mpv_options_audio)))
end

function ass.show()
    local line = util.escape_py(util.get_current_line(vim.api.nvim_get_current_win()))
    util.py(string.format('ass.show_line("%s")', line))
end

function ass.play_line(opt, background)
    local line = util.escape_py(util.get_current_line(vim.api.nvim_get_current_win()))
    local res = util.pyeval(string.format('ass.get_play_cmd("%s", "%s", %s)', line, opt, background and "True" or "False"))
    if res ~= nil and res ~= vim.NIL then
        vim.cmd("!" .. res)
        vim.fn.feedkeys("<CR>")     -- close the "Enter" prompt
    end
end

function ass.split_line()
    local win = vim.api.nvim_get_current_win()
    local c = vim.api.nvim_win_get_cursor(win)
    local buf = vim.api.nvim_get_current_buf()

    local lines = vim.api.nvim_buf_get_lines(buf, c[1] - 1, c[1] + 1, false)
    if #lines < 2 then return end

    local res = util.pyeval(string.format('ass.split_line("%s", "%s", %d)', util.escape_py(lines[1]), util.escape_py(lines[2]), c[2]))
    if res ~= nil and res ~= vim.NIL then
        vim.api.nvim_buf_set_lines(buf, c[1] - 1, c[1] + 1, false, res)
    end
end

function ass.join_cursor(count)
    local win = vim.api.nvim_get_current_win()
    local c = vim.api.nvim_win_get_cursor(win)
    ass.join(c[1] - 1, c[1] + count - 1)
end

function ass.join(from, to)
    local buf = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(buf, from, to + 1, false)

    local res = util.pyeval(string.format('ass.join_lines(%s)', util.python_list(lines)))
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
