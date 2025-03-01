local uv = vim.uv
local Mark = require("codemarks.mark")
local utils = require("codemarks.utils")

---@class CodeMarks.Marks
---@field opts table
---@field marks table<string, CodeMarks.Mark>
Marks = {}
Marks.__index = Marks

---@class CodeMarks.Marks.Opts
---@field marks_file string

--- Creates a new instance of Marks
---@param opts CodeMarks.Marks.Opts
---@return CodeMarks.Marks
function Marks:new(opts)
  local c = {}
  setmetatable(c, Marks)
  c.opts = opts

  -- load marks file
  c.marks = {}
  local file = io.open(opts.marks_file, "r")
  if file then
    for line in file:lines() do
      local mark = Mark.from_line(line)
      c.marks[mark.root] = c.marks[mark.root] or {}
      table.insert(c.marks[mark.root], mark)
    end
    file:close()
  else
    error("Could not open file: " .. opts.marks_file)
  end
  return c
end

--- Add a mark
---@param desc string Describe the mark
function Marks:add(desc)
  local file_path = vim.api.nvim_buf_get_name(0)
  local pos = vim.api.nvim_win_get_cursor(0)
  local root = utils.path.get_root_dir()
  ---@type CodeMarks.MarkData
  local data = {
    desc = desc,
    root = root,
    file = file_path,
    lineno = pos[1],
  }
  local mark = Mark:new(data)
  self.marks[mark.root] = self.marks[mark.root] or {}
  table.insert(self.marks[mark.root], mark)
  self:save({ mode = "a", lines = mark:serialize() .. "\n" })
end

--- Save marks to file
---@param opts table {lines: string?, mode: string?}
function Marks:save(opts)
  opts = opts or {}
  local lines = opts.lines
  if lines == nil then
    lines = {}
    for _, mark in pairs(self.marks) do
      table.insert(lines, mark:serialize())
    end
    lines = table.concat(lines, "\n")
  end

  local mode = opts.mode or "w"
  uv.fs_open(self.opts.marks_file, mode, 438, function(err, fd)
    if err then
      error("Could not open file: " .. self.opts.marks_file)
      return
    end

    uv.fs_write(fd, lines, -1, function(ws_err)
      if ws_err then
        error("Could not write to file: " .. self.opts.marks_file)
      end
      uv.fs_close(fd, function(close_err)
        if close_err then
          error("Could not close file: " .. self.opts.marks_file)
        end
      end)
    end)
  end)
end

return Marks
