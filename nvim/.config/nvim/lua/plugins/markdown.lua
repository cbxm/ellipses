local M = {}

local function toggle_line(line)
  if line:match("^%s*- %[x%]") then
    return (line:gsub("- %[x%]", "- [ ]", 1))
  elseif line:match("^%s*- %[ %]") then
    return (line:gsub("- %[ %]", "- [x]", 1))
  elseif line:match("^%s*- ") then
    return (line:gsub("(- )", "- [ ] ", 1))
  else
    return "- [ ] " .. line:gsub("^%s*", "")
  end
end

function M.toggle_checkbox()
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_set_current_line(toggle_line(line))
end

function M.toggle_checkbox_visual()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  for lnum = start_line, end_line do
    local line = vim.fn.getline(lnum)
    vim.fn.setline(lnum, toggle_line(line))
  end
end

return M
