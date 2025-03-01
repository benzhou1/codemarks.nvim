local Path = require("plenary.path")
local M = { path = {}, cache = { git_dirs = {} } }

--- Get the last part of a path
---@param path string
---@return string
function M.path.basename(path)
  local name = string.gsub(path, "(.*/)(.*)", "%2")
  return name
end

--- Find the git directory of the current file
---@return string|boolean
function M.path.find_git_dir()
  local current_path = vim.fn.expand("%:p:h")
  while current_path do
    -- Check if we have already found the git dir before
    if M.cache.git_dirs[current_path] ~= nil then
      return M.cache.git_dirs[current_path]
    end

    local git_path = Path:new(current_path, ".git")
    if git_path:exists() then
      M.cache.git_dirs[current_path] = git_path:absolute()
      return M.cache.git_dirs[current_path]
    end
    current_path = Path:new(current_path):parent():absolute()
    if current_path == Path.path.root(current_path) then
      break
    end
  end

  M.cache.git_dirs[current_path] = false
  return false
end

--- Gets the root dir based on the current file
function M.path.get_root_dir()
  local git_dir = M.path.find_git_dir()
  local root = nil
  if git_dir then
    root = M.path.basename(Path:new(git_dir):parent().filename)
  else
    root = "rootless"
  end
  return root
end

return M
