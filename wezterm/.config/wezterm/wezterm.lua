local wezterm = require 'wezterm';
local io = require 'io';
local os = require 'os';

local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.color_scheme = 'dawnfox'
config.term = 'wezterm'
config.front_end = 'WebGpu'
config.enable_wayland = false

config.font = wezterm.font_with_fallback {
  'CommitMono', 'Symbols Nerd Font Mono'
}
config.font_size = 10.5
config.warn_about_missing_glyphs = false

config.hide_tab_bar_if_only_one_tab = true
config.enable_scroll_bar = true
config.scrollback_lines = 10000
config.audible_bell = 'Disabled'

config.exit_behavior = 'Close'
config.clean_exit_codes = {130}

config.initial_rows = 60
config.initial_cols = 200

wezterm.on("trigger-vim-with-scrollback", function(window, pane)
  -- Retrieve the current viewport's text.
  -- Pass an optional number of lines (eg: 2000) to retrieve
  -- that number of lines starting from the bottom of the viewport
  local scrollback =
    pane:get_lines_as_text(pane:get_dimensions().scrollback_rows);

  -- Create a temporary file to pass to vim
  local name = os.tmpname();
  local f = io.open(name, "w+");
  f:write(scrollback);
  f:flush();
  f:close();

  -- Open a new window running vim and tell it to open the file
  window:perform_action(wezterm.action { SpawnCommandInNewWindow = {
    args = { "nvim", name } }
  }, pane)

  -- wait "enough" time for vim to read the file before we remove it.
  -- The window creation and process spawn are asynchronous
  -- wrt. running this script and are not awaitable, so we just pick
  -- a number.
  wezterm.sleep_ms(1000);
  os.remove(name);
end)

wezterm.on('toggle-colorscheme', function(window, pane)
  local overrides = window:get_config_overrides() or {}
  if not overrides.color_scheme then
    overrides.color_scheme = 'carbonfox'
  else
    overrides.color_scheme = nil
  end
  window:set_config_overrides(overrides)
end)

wezterm.on('toggle-ligature', function(window, pane)
  local overrides = window:get_config_overrides() or {}
  if not overrides.harfbuzz_features then
    -- If we haven't overridden it yet, then override with ligatures disabled
    overrides.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }
  else
    -- else we did already, and we should disable out override now
    overrides.harfbuzz_features = nil
  end
  window:set_config_overrides(overrides)
end)

config.keys = {
  {
    key = 't', mods = 'CTRL',
    action = wezterm.action.SpawnTab 'CurrentPaneDomain'
  },
  {
    key='o', mods='CTRL',
    action=wezterm.action.EmitEvent 'trigger-vim-with-scrollback'
  },
  {
    key='e', mods='SHIFT|CTRL',
    action = wezterm.action.EmitEvent 'toggle-colorscheme'
  },
  {
    key = 'f',
    mods = 'SHIFT|CTRL',
    action = wezterm.action.EmitEvent 'toggle-ligature',
  },
  {
    key='|', mods='SHIFT|CTRL',
    action = wezterm.action.SplitHorizontal { domain='CurrentPaneDomain' }
  },
  {
    key='|', mods='SHIFT|CTRL|ALT',
    action = wezterm.action.SplitVertical { domain='CurrentPaneDomain' }
  },
}

return config
