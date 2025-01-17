-- document existing key chains
require('which-key').add({
  { "<leader>c",  group = "[C]ode" },
  { "<leader>cc", group = "[C]opilot [C]hat" },
  { '<leader>d',  group = '[D]ocument' },
  { '<leader>g',  group = '[G]it' },
  { '<leader>r',  group = '[R]ename' },
  { '<leader>s',  group = '[S]earch' },
  { '<leader>t',  group = '[T]oggle' },
  { '<leader>tc', group = '[T]oggle [C]opilot' },
  { '<leader>w',  group = '[W]orkspace' },
});


require('which-key').add({
  { "<leader>c", group = "[C]opilot", mode = "v" },
});
