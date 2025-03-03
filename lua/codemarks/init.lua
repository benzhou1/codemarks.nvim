local Marks = require("codemarks.marks")
local Path = require("plenary.path")
local pickers = require("codemarks.pickers")
local M = {}

---@class CodeMarks.Config
---@field marks_file string? The path to the marks file
---@field pick_opts snacks.picker.Config? Options for snacks picker
---@type CodeMarks.Config
M.config = {
  marks_file = vim.fn.stdpath("data") .. "/codemarks/codemarks.txt",
  pick_opts = {
    layout = {
      layout = {
        width = 0.6,
        height = 0.6,
        title = "{title}",
      },
    },
    win = {
      input = {
        keys = {
          ["<esc>"] = {
            "switch_to_list",
            mode = { "i" },
            desc = "Switch to the list view",
          },
          ["<c-g>"] = {
            "toggle_global",
            mode = { "i", "n" },
            desc = "Toggle to show all marks",
          },
        },
      },
      list = {
        keys = {
          ["dd"] = {
            "delete",
            desc = "Delete current mark",
          },
          ["a"] = {
            "toggle_focus",
            desc = "Focus input",
          },
          ["i"] = {
            "toggle_focus",
            desc = "Focus input",
          },
          ["r"] = {
            "rename_mark",
            desc = "Updates the mark description",
          },
        },
      },
    },
  },
}

--- Setup the plugin
---@param opts CodeMarks.Config
function M.setup(opts)
  M.config = vim.tbl_deep_extend("keep", opts or {}, M.config)
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
  M.marks = Marks:new({ marks_file = M.config.marks_file })
end

--- Find code marks
---@param opts snacks.picker.Config? Options for snacks picker
function M.picker(opts)
  local pick_opts = vim.tbl_deep_extend("keep", opts or {}, M.config.pick_opts)
  pickers.marks.finder(pick_opts)
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
