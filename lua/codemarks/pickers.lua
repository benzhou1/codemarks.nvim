local utils = require("codemarks.utils")
local M = { marks = {} }

--- Picker for searching marks
function M.marks.finder()
  local show_global = false
  local cur_win = vim.api.nvim_get_current_win()
  local function marks_finder(_, ctx)
    local marks = require("codemarks").marks
    local filter_marks = {}
    if show_global then
      for _, _marks in pairs(marks.marks) do
        for _, m in ipairs(_marks) do
          table.insert(filter_marks, m)
        end
      end
    else
      local root = utils.path.get_root_dir()
      if marks.marks[root] then
        for _, m in ipairs(marks.marks[root]) do
          table.insert(filter_marks, m)
        end
      end
    end

    local items = {} ---@type snacks.picker.finder.Item[]
    for _, m in ipairs(filter_marks) do
      local item = {
        text = m.desc,
        file = m.file,
        lineno = m.lineno,
        pos = { m.lineno, 0 },
        root = m.root,
      }
      table.insert(items, item)
    end
    return ctx.filter:filter(items)
  end

  require("snacks.picker").pick({
    finder = marks_finder,
    format = function(item, _)
      return { { item.text } }
    end,
    layout = {
      preview = false,
    },
    supports_live = false,
    actions = {},
    win = {
      input = {
        keys = {},
      },
    },
  })
end

return M
