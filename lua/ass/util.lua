util = {
  py_loaded = false,
}

function util._py_check_loaded()
  if not util.py_loaded then
    require'ass'.python_init()
  end
  util.py_loaded = true
end

function util.py(cmd)
  util._py_check_loaded()
  vim.cmd("py3 " .. cmd)
end

function util.pyeval(cmd)
  util._py_check_loaded()
  return vim.fn.py3eval(cmd)
end

function util.escape_py(str)
    return str
        :gsub('\\', '\\\\')
        :gsub('"', '\\"')
end

function util.python_list(list)
    local entries = ""
    for _, k in ipairs(list) do
        entries = entries .. string.format('"%s",', util.escape_py(k))
    end
    return string.format("[%s]", entries)
end

function util.get_current_line(win)
    local buf = vim.api.nvim_win_get_buf(win)
    local c = vim.api.nvim_win_get_cursor(win)

    return vim.api.nvim_buf_get_lines(buf, c[1] - 1, c[1], true)[1]
end

function util.set_current_line(win, line)
    local buf = vim.api.nvim_win_get_buf(win)
    local c = vim.api.nvim_win_get_cursor(win)

    return vim.api.nvim_buf_set_lines(buf, c[1] - 1, c[1], true, {line})
end

function util.move_cursor(win, dy)
    local c = vim.api.nvim_win_get_cursor(win)
    local buf = vim.api.nvim_win_get_buf(win)
    local buf_height = vim.api.nvim_buf_line_count(buf)

    local newy = c[1] + dy
    if newy < 1 then newy = 1 end
    if newy > buf_height then newy = buf_height end
    vim.api.nvim_win_set_cursor(win, {newy, c[2]})
    vim.api.nvim__buf_redraw_range(buf, 0, buf_height)
end

return util
