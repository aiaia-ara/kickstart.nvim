-- DAP debugging for Python, JavaScript/TypeScript, C (+C++/Rust), and Go,
-- written for the CURRENT kickstart.nvim (vim.pack, Neovim 0.12+).
--
-- Imperative vim.pack module: adds the plugins and configures them inline.
-- Auto-sourced once `require 'custom.plugins'` is uncommented in init.lua.
--
-- One-time adapter install (uses the mason kickstart already bundles):
--   :MasonInstall debugpy js-debug-adapter codelldb delve
--
-- NOTE: your init.lua already installs `gopls` and other LSP servers via
-- mason-tool-installer; this file only adds the *debug* adapters.
--
-- Paths assume macOS/Linux. On Windows swap:
--   debugpy/venv/bin/python              -> debugpy/venv/Scripts/python
--   codelldb/extension/adapter/codelldb  -> ...\codelldb.exe

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add {
  gh 'mfussenegger/nvim-dap',
  gh 'rcarriga/nvim-dap-ui',
  gh 'nvim-neotest/nvim-nio', -- required by nvim-dap-ui
  gh 'theHamsta/nvim-dap-virtual-text',
  gh 'mfussenegger/nvim-dap-python',
  gh 'leoluz/nvim-dap-go',

  -- If `:Mason` does NOT already work in your kickstart, uncomment the next
  -- line AND the require('mason').setup() call below. Your init.lua already
  -- installs and sets up mason in its LSP section (SECTION 6), so normally
  -- leave this commented.
  -- gh 'mason-org/mason.nvim',
}

local dap = require 'dap'
local dapui = require 'dapui'
local data = vim.fn.stdpath 'data' -- mason installs under here

-- require('mason').setup()  -- only if you uncommented mason above

--------------------------------------------------------------------------
-- 1. Python  (debugpy, via nvim-dap-python)
--------------------------------------------------------------------------
require('dap-python').setup(data .. '/mason/packages/debugpy/venv/bin/python')

--------------------------------------------------------------------------
-- 2. JavaScript / TypeScript  (js-debug-adapter, pwa-node)
--------------------------------------------------------------------------
local js_debug = data .. '/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js'

dap.adapters['pwa-node'] = {
  type = 'server',
  host = 'localhost',
  port = '${port}',
  executable = {
    command = 'node',
    args = { js_debug, '${port}' },
  },
}

dap.adapters['node'] = function(cb, config)
  if config.type == 'node' then config.type = 'pwa-node' end
  local native = dap.adapters['pwa-node']
  if type(native) == 'function' then
    native(cb, config)
  else
    cb(native)
  end
end

for _, lang in ipairs { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' } do
  dap.configurations[lang] = {
    {
      type = 'pwa-node',
      request = 'launch',
      name = 'Launch file',
      program = '${file}',
      cwd = '${workspaceFolder}',
      sourceMaps = true,
    },
    {
      type = 'pwa-node',
      request = 'attach',
      name = 'Attach to process',
      processId = require('dap.utils').pick_process,
      cwd = '${workspaceFolder}',
      sourceMaps = true,
    },
    {
      type = 'pwa-node',
      request = 'launch',
      name = 'Launch current file (tsx)',
      runtimeExecutable = 'tsx',
      args = { '${file}' },
      cwd = '${workspaceFolder}',
      sourceMaps = true,
      skipFiles = { '<node_internals>/**', '${workspaceFolder}/node_modules/**' },
    },
  }
end

--------------------------------------------------------------------------
-- 3. C / C++ / Rust  (codelldb)
--------------------------------------------------------------------------
dap.adapters.codelldb = {
  type = 'server',
  port = '${port}',
  executable = {
    command = data .. '/mason/packages/codelldb/extension/adapter/codelldb',
    args = { '--port', '${port}' },
  },
}

dap.configurations.c = {
  {
    name = 'Launch (prompt for binary)',
    type = 'codelldb',
    request = 'launch',
    program = function()
      -- Compile first with -g, e.g. `cc -g -o main main.c`, then point here.
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  },
}
dap.configurations.cpp = dap.configurations.c
dap.configurations.rust = dap.configurations.c

--------------------------------------------------------------------------
-- 4. Go  (delve, via nvim-dap-go)
--------------------------------------------------------------------------
-- Registers Go configs automatically: debug file, debug test, debug nearest
-- test, attach. Mirrors the detached-on-Windows guard from kickstart's stock
-- debug.lua.
require('dap-go').setup {
  delve = {
    detached = vim.fn.has 'win32' == 0,
  },
}

--------------------------------------------------------------------------
-- 5. UI: dap-ui + virtual text, auto open/close with the session
--------------------------------------------------------------------------
dapui.setup()
require('nvim-dap-virtual-text').setup()

dap.listeners.before.attach.dapui_config = function() dapui.open() end
dap.listeners.before.launch.dapui_config = function() dapui.open() end
dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DiagnosticError', numhl = '' })
vim.fn.sign_define('DapBreakpointCondition', { text = '◆', texthl = 'DiagnosticWarn', numhl = '' })
vim.fn.sign_define('DapStopped', { text = '▶', texthl = 'DiagnosticOk', linehl = 'Visual', numhl = '' })

--------------------------------------------------------------------------
-- 6. Keymaps  (<leader> is Space in kickstart)
--------------------------------------------------------------------------
-- Label the <leader>d group in which-key, if it is available.
local ok, wk = pcall(require, 'which-key')
if ok then wk.add { { '<leader>d', group = 'Debug' } } end

local map = vim.keymap.set

-- Stepping / flow
map('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
map('n', '<F10>', dap.step_over, { desc = 'Debug: Step Over' })
map('n', '<F11>', dap.step_into, { desc = 'Debug: Step Into' })
map('n', '<F12>', dap.step_out, { desc = 'Debug: Step Out' })
map('n', '<leader>dC', dap.run_to_cursor, { desc = 'Debug: Run to Cursor' })
map('n', '<leader>dx', dap.terminate, { desc = 'Debug: Terminate' })

-- Breakpoints
map('n', '<leader>b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
map('n', '<leader>B', function() dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, { desc = 'Debug: Conditional Breakpoint' })
map('n', '<leader>dp', function() dap.set_breakpoint(nil, nil, vim.fn.input 'Log point message: ') end, { desc = 'Debug: Log Point' })

-- Inspect / run tests
map({ 'n', 'v' }, '<leader>de', function() dapui.eval(nil, { enter = true }) end, { desc = 'Debug: Evaluate' })
map('n', '<leader>dt', function()
  local ft = vim.bo.filetype
  if ft == 'python' then
    require('dap-python').test_method()
  elseif ft == 'go' then
    require('dap-go').debug_test()
  else
    vim.notify('No test runner for filetype: ' .. ft, vim.log.levels.WARN)
  end
end, { desc = 'Debug: Nearest Test' })

-- Windows
map('n', '<leader>dr', dap.repl.open, { desc = 'Debug: Open REPL' })
map('n', '<leader>du', dapui.toggle, { desc = 'Debug: Toggle UI' })
map('n', '<leader>dl', dap.run_last, { desc = 'Debug: Run Last' })
