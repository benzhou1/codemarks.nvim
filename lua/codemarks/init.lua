local Marks = require("codemarks.marks")
local Path = require("plenary.path")
local pickers = require("codemarks.pickers")
local M = {}

---@class CodeMarks.Config
---@field marks_file string? The path to the marks file
---@type CodeMarks.Config
M.config = {
  marks_file = vim.fn.stdpath("data") .. "/codemarks/codemarks.txt",
}

--- Setup the plugin
---@param opts CodeMarks.Config
function M.setup(opts)
  opts = vim.tbl_deep_extend("keep", opts or {}, M.config)
  local marks_file = Path:new(opts.marks_file)
  local parent = marks_file:parent()

  -- Marks sure the parent exists
  if not parent:exists() then
    parent:mkdir()
  end
  -- Marks sure the marks file exists
  if not marks_file:exists() then
    marks_file:write("", "w")
  end

  -- Load the marks file
  M.marks = Marks:new({ marks_file = opts.marks_file })
end

--- Find code marks
---@param opts table
function M.picker(opts)
  pickers.marks.finder()
end

--- Add a new code mark
function M.add()
  vim.ui.input({ prompt = "Describe the mark" }, function(res)
    if res == nil then
      return
    end
    M.marks:add(res)
  end)
end

return M
