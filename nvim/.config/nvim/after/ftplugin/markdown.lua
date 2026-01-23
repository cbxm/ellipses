vim.keymap.set("n", "<leader>tt", function()
  require("plugins.markdown").toggle_checkbox()
end, { buffer = true, desc = "Toggle markdown checkbox" })

vim.keymap.set("v", "<leader>tt", function()
  require("plugins.markdown").toggle_checkbox_visual()
end, { buffer = true, desc = "Toggle markdown checkboxes" })
