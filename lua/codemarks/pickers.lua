local utils = require("codemarks.utils")
local M = { marks = {}, actions = {}, flags = { global = false } }

--- Sets the picker title based on flags
---@param overrides table?
---@return string
local function get_title(overrides)
  local flags = vim.tbl_deep_extend("keep", overrides or {}, M.flags)
  if flags.global then
    return "Search all marks"
  end
  return "Search marks"
end

--- Picker action to delete the currently selected item
function M.actions.delete(picker)
  local item = picker:selected({ fallback = true })[1]
  if item == nil then
    return
  end

  local marks = require("codemarks").marks
  marks:del(item.data)

  picker:close()
  vim.schedule(function()
    require("snacks.picker").resume()
  end)
end

--- Focus the list window
function M.actions.switch_to_list(picker)
  require("snacks.picker.actions").cycle_win(picker)
  require("snacks.picker.actions").cycle_win(picker)
end

--- Toggles global flag
function M.actions.toggle_global(picker)
  M.flags.global = not M.flags.global
  picker:close()
  vim.schedule(function()
    -- HACK: This is a hack to update the title of the picker after resuming
    picker.last.opts.title = get_title()
    picker:resume()
  end)
end

--- Updates the description of the mark under the cursor
function M.actions.update_desc(picker)
  local item = picker:selected({ fallback = true })[1]
  if item == nil then
    return
  end

  local marks = require("codemarks").marks
  local mark = marks:get(item.data)
  if mark == nil then
    return
  end

  vim.ui.input({ prompt = "Update the mark desription", default = mark.desc }, function(res)
    if res == nil then
      return
    end
    picker:close()
    marks:update(item.data, { desc = res }, function()
      vim.schedule(function()
        picker:resume()
      end)
    end)
  end)
end

--- Picker for searching marks
function M.marks.finder(opts)
  local function marks_finder(_, ctx)
    local marks = require("codemarks").marks
    local filter_marks = {}
    if not M.flags.global then
      local root = utils.path.get_root_dir()
      for _, m in pairs(marks.marks) do
        if m.root == root then
          table.insert(filter_marks, m)
        end
      end
      if #filter_marks == 0 then
        vim.notify("No marks found, showing all marks...", vim.log.levels.WARN)
        M.flags.global = true
      end
    end

    if M.flags.global then
      for _, m in pairs(marks.marks) do
        table.insert(filter_marks, m)
      end
    end

    local items = {} ---@type snacks.picker.finder.Item[]
    for _, m in ipairs(filter_marks) do
      local item = {
        text = m.desc,
        file = m.file,
        pos = { m.lineno, 0 },
        data = m.data,
        flags = "root",
      }
      table.insert(items, item)
    end

    ctx.picker.title = get_title()
    return ctx.filter:filter(items)
  end

  local pick_opts = vim.tbl_deep_extend("keep", opts or {}, {
    title = get_title(),
    finder = marks_finder,
    format = function(item, _)
      return { { item.text } }
    end,
    matcher = {
      frecency = true,
      sort_empty = true,
      file_pos = false,
    },
    supports_live = false,
    actions = {
      delete = M.actions.delete,
      switch_to_list = M.actions.switch_to_list,
      toggle_global = M.actions.toggle_global,
      rename_mark = M.actions.update_desc,
    },
    win = {
      title = "{title}",
    },
  })

  require("snacks.picker").pick(pick_opts)
end

return M
