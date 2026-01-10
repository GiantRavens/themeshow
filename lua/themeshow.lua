local M = {}

local state = {
  active = false,
  timer = nil,
  themes = {},
  index = 1,
  prev_maps = {},
  saved = false,
  expanded = false,
}

local base_themes = { "tokyonight", "nord", "solarized", "base16-railscasts" }

local function apply_theme(name)
  local ok, err = pcall(vim.cmd.colorscheme, name)
  if not ok then
    vim.api.nvim_echo({ { "colorscheme failed: " .. name .. " (" .. tostring(err) .. ")", "WarningMsg" } }, true, {})
    return false
  end
  vim.api.nvim_echo({ { "themeshow: " .. name, "MoreMsg" } }, true, {})
  return true
end

local function expand_themes()
  if state.expanded then
    return
  end

  local all = vim.fn.getcompletion("", "color")
  table.sort(all)

  local seen = {}
  for _, theme in ipairs(state.themes) do
    seen[theme] = true
  end

  for _, theme in ipairs(all) do
    if not seen[theme] then
      table.insert(state.themes, theme)
    end
  end

  state.expanded = true
  vim.api.nvim_echo({ { "themeshow: expanded list (" .. tostring(#state.themes) .. " themes)", "MoreMsg" } }, true, {})
end

local function save_default(name)
  local init_path = vim.fn.stdpath("config") .. "/init.lua"
  local lines = vim.fn.readfile(init_path)
  local replaced = false

  for i, line in ipairs(lines) do
    if line:match("^vim%.cmd%.colorscheme%(") then
      lines[i] = "vim.cmd.colorscheme(\"" .. name .. "\")"
      replaced = true
      break
    end
  end

  if not replaced then
    table.insert(lines, "")
    table.insert(lines, "vim.cmd.colorscheme(\"" .. name .. "\")")
  end

  vim.fn.writefile(lines, init_path)
end

local function step(dir)
  local count = #state.themes
  if count == 0 then
    return
  end

  if dir == 1 and state.index == count and not state.expanded then
    expand_themes()
    count = #state.themes
    if count > state.index then
      state.index = state.index + 1
    else
      state.index = 1
    end
  else
    state.index = ((state.index - 1 + dir) % count) + 1
  end

  apply_theme(state.themes[state.index])
end

local function stop_cycle(save)
  if not state.active then
    return
  end
  state.active = false
  if state.timer then
    state.timer:stop()
    state.timer:close()
    state.timer = nil
  end

  -- restore previous mappings if they existed
  for _, key in ipairs({ "<Right>", "<Left>", "<CR>", "<Esc>" }) do
    local prev = state.prev_maps[key]
    if prev and prev.rhs then
      vim.fn.mapset(prev)
    else
      pcall(vim.keymap.del, "n", key)
    end
  end

  if save then
    local name = state.themes[state.index]
    save_default(name)
    vim.api.nvim_echo({ { "themeshow: default set to " .. name, "MoreMsg" } }, true, {})
  end
end

local function start_cycle(interval_ms)
  if state.active then
    return
  end
  state.active = true
  state.saved = false
  state.expanded = false
  state.themes = vim.deepcopy(base_themes)
  state.index = 1

  -- capture existing mappings so we can restore them
  state.prev_maps = {}
  for _, key in ipairs({ "<Right>", "<Left>", "<CR>", "<Esc>" }) do
    state.prev_maps[key] = vim.fn.maparg(key, "n", false, true)
  end

  vim.keymap.set("n", "<Right>", function()
    step(1)
  end, { silent = true })
  vim.keymap.set("n", "<Left>", function()
    step(-1)
  end, { silent = true })
  vim.keymap.set("n", "<CR>", function()
    stop_cycle(true)
  end, { silent = true })
  vim.keymap.set("n", "<Esc>", function()
    stop_cycle(false)
  end, { silent = true })

  if interval_ms and interval_ms > 0 then
    state.timer = vim.loop.new_timer()
    state.timer:start(0, interval_ms, vim.schedule_wrap(function()
      if state.active then
        step(1)
      end
    end))
  end

  vim.api.nvim_echo({ { "themeshow: left/right to browse, enter to save, esc to cancel", "MoreMsg" } }, true, {})
end

function M.setup()
  vim.api.nvim_create_user_command("ThemeShow", function()
    start_cycle(nil)
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("ThemeShowAuto", function(opts)
    local ms = tonumber(opts.args)
    if not ms or ms <= 0 then
      ms = 2000
    end
    start_cycle(ms)
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("ThemeShowStop", function()
    stop_cycle(false)
  end, {})
end

return M
