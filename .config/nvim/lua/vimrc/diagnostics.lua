local S = vim.diagnostic.severity

local sign_hl = {
  [S.ERROR] = 'DiagnosticSignError',
  [S.WARN] = 'DiagnosticSignWarn',
  [S.HINT] = 'DiagnosticSignHint',
  [S.INFO] = 'DiagnosticSignInfo',
}

vim.diagnostic.config({
  virtual_text = {
    current_line = true,
  },
  severity_sort = true,
  signs = {
    text = {
      [S.ERROR] = '󰅚',
      [S.WARN] = '󰀪',
      [S.HINT] = '󰌶',
      [S.INFO] = '󰋽',
    },
    linehl = sign_hl,
    numhl = sign_hl,
  },
})
