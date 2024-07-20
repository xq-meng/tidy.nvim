local M = {}

M.opts = {
  enabled_on_save = true,
  filetype_exclude = {},
}


function M.toggle()
  M.opts.enabled_on_save = not M.opts.enabled_on_save

  if not M.opts.enabled_on_save then
    vim.notify("Tidy disabled on save", vim.log.levels.WARN, { title = "Tidy" })
  else
    vim.notify("Tidy enabled on save", vim.log.levels.INFO, { title = "Tidy" })
  end
end

local function is_excluded_ft(excluded_fts)
  local ft = vim.api.nvim_buf_get_option(0, "filetype")
  local contains = vim.fn.has('nvim-0.10') == 1 and vim.list_contains or vim.tbl_contains

  return contains(excluded_fts, ft)
end

local function reset_cursor_pos(pos)
  local num_rows = vim.api.nvim_buf_line_count(0)

  --[[
        if the row value in the original cursor
        position tuple is greater than the
        line count after empty line deletion
        (meaning that the cursor was inside of
        the group of empty lines at the end of
        the file when they were deleted), set
        the cursor row to the last line.
    ]]
  if pos[1] > num_rows then
    pos[1] = num_rows
  end

  vim.api.nvim_win_set_cursor(0, pos)
end

function M.run()
  if is_excluded_ft(M.opts.filetype_exclude) or
      (vim.b.editorconfig ~= nil and not vim.tbl_isempty(vim.b.editorconfig)) then
    return false
  end

  local cursor_pos = vim.api.nvim_win_get_cursor(0)

  -- delete trailing whitespace
  vim.cmd([[:keepjumps keeppatterns %s/\s\+$//e]])

  reset_cursor_pos(cursor_pos)
end

function M.setup(opts)
  M.opts = vim.tbl_extend("force", M.opts, opts or {})

  local tidy_grp = vim.api.nvim_create_augroup("tidy", { clear = true })

  vim.api.nvim_create_autocmd("BufWritePre", {
    group = tidy_grp,
    callback = function()
      if not M.opts.enabled_on_save then
        return false
      end

      M.run()
    end
  })
end

return M
