local ass = {}

local util = require'ass.util'

vim.cmd("py3 import ass")

function ass.setup(opts)
    opts = opts or {}

    vim.cmd[[
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
    ]]

    if opts.submode == true then
        vim.g['submode_timeout'] = false
        vim.call("submode#enter_with", "ass_split", "n", "", ",a")
        vim.call("submode#leave_with", "ass_split", "n", "", "q")
        vim.call("submode#leave_with", "ass_split", "n", "", "<Esc>")
        -- -- vim.call("submode#map", "ass_split", "n", "", "j", "<Plug>AssSplitDown")

        for _, c in ipairs({"h", "j", "k", "l"}) do
            vim.call("submode#map", "ass_split", "n", "", c, c)
        end
    end

    if opts.conceal == true then
        vim.cmd[[
            autocmd FileType ass lua require'ass'.setup_conceal()
        ]]
    end

    if opts.remap_keys then
        vim.cmd[[
            autocmd FileType ass nnoremap <BS> <Cmd>AssReplace<CR>
            autocmd FileType ass nnoremap <expr> <CR> '<Cmd>AssReplaceMove' . v:count1 . '<CR>'
            autocmd FileType ass nnoremap <expr> <Tab> '<Cmd>AssAppend' . v:count1 . '<CR>'
            autocmd FileType ass nnoremap <expr> ü '<Cmd>AssSplitUp' . v:count1 . '<CR>'
            autocmd FileType ass nnoremap <expr> ä '<Cmd>AssSplitDown' . v:count1 . '<CR>'
            autocmd FileType ass nnoremap <expr> J '<Cmd>AssJoin' . v:count1 . '<CR>'
            autocmd FileType ass nnoremap <leader>s <Cmd>AssShow<CR>
            autocmd FileType ass vnoremap J :AssJoinRange<CR>
            autocmd FileType ass nnoremap _ 09f,l
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
    local name = util.escape_py(vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()))
    vim.fn.py3eval(string.format('ass.show("%s", "%s")', line, name))
end

function ass.join(from, to)
    local buf = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(buf, from, to + 1, false)

    local pythonlist = ""
    for _, k in ipairs(lines) do
        pythonlist = pythonlist .. string.format('"%s",', util.escape_py(k))
    end

    local res = vim.fn.py3eval(string.format('ass.join_lines([%s])', pythonlist))
    if res ~= nil then
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
