-- based on code from github.com/leanprover/lean.nvim
local split = {
    _by_id = {},
    _by_tabpage = {},
}

local util = require'ass.util'
local ass = require'ass'

-- @class SplitWin
-- @field id
-- @field is_open
-- @field window
-- @field parent_window
-- @field last_cursor_pos
-- @field in_operation
local SplitWin = {}

function split._ensure_exists()
    local page = vim.api.nvim_win_get_tabpage(0)
    if not split._by_tabpage[page] then
        split._by_tabpage[page] = SplitWin:new()
    end
end

function split.get_current_split()
    return split._by_tabpage[vim.api.nvim_win_get_tabpage(0)]
end

function split.open()
    split._ensure_exists()
    split.get_current_split():open(filename) 
end

function split.open_ass(filename)
    split._ensure_exists()
    split.get_current_split():open_ass(filename) 
end

function split.follow_cursor()
    split._ensure_exists()
    split.get_current_split():follow_cursor() 
end

function split.cursor_up(count)
    split._ensure_exists()
    split.get_current_split():move_cursor(-count) 
end

function split.cursor_down(count)
    split._ensure_exists()
    split.get_current_split():move_cursor(count) 
end

function split.replace()
    split._ensure_exists()
    split.get_current_split():process_line("replace_line")
end

function split.replace_move(count)
    split._ensure_exists()
    split.get_current_split():replace_move(count)
end

function split.append(count)
    split._ensure_exists()
    for i = 1, count do
        split.get_current_split():process_line("append_line")
        split.cursor_down(1)
    end
end

function SplitWin:new()
    local new_splitwin = {
        id = #split._by_id + 1,
    }
    table.insert(split._by_id, new_splitwin)
    self.__index = self
    setmetatable(new_splitwin, self)
    return new_splitwin
end

function SplitWin:open()
    if self.is_open then return end

    self.parent_window = vim.api.nvim_get_current_win()
    vim.cmd("botright vnew")  
    self.window = vim.api.nvim_get_current_win()
    self:focus_parent()

    vim.cmd[[
        autocmd CursorMoved * lua require'ass.split'.follow_cursor()
    ]]

    self.is_open = true
end

function SplitWin:focus()
    vim.api.nvim_set_current_win(self.window)
end

function SplitWin:focus_parent()
    vim.api.nvim_set_current_win(self.parent_window)
end

function SplitWin:open_ass(filename)
    self:open()

    self:focus()
    vim.cmd("e " .. filename)
    vim.opt.cursorline=true
    self:focus_parent()

    self:reset_cursor()
end

function SplitWin:reset_cursor()
    self.last_cursor_pos = vim.api.nvim_win_get_cursor(self.parent_window)
end

function SplitWin:follow_cursor()
    if not (self.is_open and vim.api.nvim_get_current_win() == self.parent_window) then return end
    if not self.last_cursor_pos or self.in_operation then return end

    local pc = vim.api.nvim_win_get_cursor(self.parent_window)
    if pc[1] ~= self.last_cursor_pos[1] then
        self:move_cursor(pc[1] - self.last_cursor_pos[1])
    end
        
    self.last_cursor_pos = pc
end

function SplitWin:move_cursor(dy)
    if not (self.is_open and vim.api.nvim_get_current_win() == self.parent_window) then return end

    util.move_cursor(self.window, dy)
end

function SplitWin:replace_move(count)
    -- just disable the follow so there's no funny business with the hooks
    self.in_operation = true
    for i = 1, count do
        split.get_current_split():process_line("replace_line")
        util.move_cursor(vim.api.nvim_get_current_win(), 1)
        self:move_cursor(1)
    end
    self:reset_cursor()
    self.in_operation = false
end

function SplitWin:process_line(pyfun)
    if not (self.is_open and vim.api.nvim_get_current_win() == self.parent_window) then return end

    local linel = util.escape_py(util.get_current_line(self.parent_window))
    local liner = util.escape_py(util.get_current_line(self.window))

    local res = util.pyeval(string.format('ass.%s("%s", "%s")', pyfun, linel, liner))
    if res ~= nil and res ~= vim.NIL then
        util.set_current_line(self.parent_window, res)
        ass.filter_lines_cursor(1, {linel})
    end
end

return split
