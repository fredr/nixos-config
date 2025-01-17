require("CopilotChat").setup({
  highlight_headers = false,
  separator = '---',
  error_header = '> [!ERROR] Error',
})

-- open copilot chat for selection
vim.keymap.set('v', '<leader>cc', function()
  require("CopilotChat").ask()
end, { desc = "[C]opilot [C]hat" })

-- open copilot chat for selection
vim.keymap.set('n', '<leader>tcc', function()
  require("CopilotChat").toggle()
end, { desc = "[T]oggle [C]opilot [C]hat" })

vim.keymap.set('n', '<leader>ccq', function()
  local input = vim.fn.input("Prompt: ")
  if input ~= "" then
    require("CopilotChat").ask(input, { selection = require("CopilotChat.select").buffer })
  end
end, { desc = "[C]opilot [C]hat [Q]uick" })
