local uv = vim.uv
local Mark = require("codemarks.mark")
local utils = require("codemarks.utils")

--- Unique key for the mark
---@param data CodeMarks.MarkData
---@return string
local function get_key(data)
  return data.file .. ":" .. data.lineno
end

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
      c.marks[get_key(mark.data)] = mark
    end
    file:close()
  else
    error("Could not open file: " .. opts.marks_file)
  end
  return c
end

--- Returns a mark based on data
---@param data CodeMarks.MarkData
---@return CodeMarks.Mark?
function Marks:get(data)
  local key = get_key(data)
  return self.marks[key]
end

--- Add a mark
---@param desc string Describe the mark
function Marks:add(desc)
  local file_path = vim.api.nvim_buf_get_name(0)
  local pos = vim.api.nvim_win_get_cursor(0)
  local root = utils.path.get_root_dir()
  local line = vim.api.nvim_get_current_line()
  ---@type CodeMarks.MarkData
  local data = {
    desc = desc,
    root = root,
    file = file_path,
    lineno = pos[1],
    line = line,
  }
  local mark = Mark:new(data)
  local key = get_key(data)
  if self.marks[key] then
    vim.notify("Mark already exists...", vim.log.levels.WARN)
    return
  end

  self.marks[key] = mark
  self:save({
    mode = "a",
    lines = mark:serialize() .. "\n",
    cb = function()
      vim.notify("Mark created...", vim.log.levels.INFO)
    end,
  })
end

--- Updates the data of a mark
---@param data CodeMarks.MarkData
---@param updates {desc: string?}
---@param cb function?
function Marks:update(data, updates, cb)
  local mark = self:get(data)
  local updated = false
  if mark ~= nil then
    if updates.desc ~= nil then
      mark:update_desc(updates.desc)
      updated = true
    end
    if updated then
      self:save({
        cb = function()
          vim.notify("Updated mark...", vim.log.levels.INFO)
          if cb ~= nil then
            cb()
          end
        end,
      })
    end
  end
end

--- Delete a mark
---@param data CodeMarks.MarkData
function Marks:del(data)
  local key = get_key(data)
  if self.marks[key] then
    self.marks[key] = nil
    self:save({
      cb = function()
        vim.notify("Mark deleted...", vim.log.levels.INFO)
      end,
    })
  end
end

--- Save marks to file
---@param opts {cb: function?}
function Marks:save(opts)
  opts = opts or {}
  local lines = ""
  for _, mark in pairs(self.marks) do
    lines = lines .. mark:serialize() .. "\n"
  end

  uv.fs_open(self.opts.marks_file, "w", 438, function(err, fd)
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
        if opts.cb ~= nil then
          opts.cb()
        end
      end)
    end)
  end)
end

return Marks
