---@class CodeMarks.MarkData
---@field desc string
---@field file string
---@field lineno integer
---@field root string
---@field line string

---@class CodeMarks.Mark: CodeMarks.MarkData
---@field line string
---@field data CodeMarks.MarkData
local Mark = {}
Mark.__index = Mark

--- Create a Mark object
---@param data CodeMarks.MarkData
---@return CodeMarks.Mark
function Mark:new(data)
  local c = {}
  setmetatable(c, Mark)
  c.data = data
  c.desc = c.data.desc
  c.file = c.data.file
  c.lineno = c.data.lineno
  c.root = c.data.root
  c.line = c.data.line
  return c
end

--- Create a Mark object from a line
---@param line string
---@return CodeMarks.Mark
function Mark.from_line(line)
  ---@type CodeMarks.MarkData
  local data = vim.fn.json_decode(line)
  return Mark:new(data)
end

--- Serialize the mark
---@return string
function Mark:serialize()
  local line = vim.fn.json_encode(self.data)
  return line
end

--- Deserialize the mark
---@return CodeMarks.MarkData
function Mark:deserialize()
  ---@diagnostic disable-next-line: return-type-mismatch
  return load(self.line)
end

--- Updates the mark's description
---@param desc string
function Mark:update_desc(desc)
  self.desc = desc
  self.data.desc = desc
end

return Mark
