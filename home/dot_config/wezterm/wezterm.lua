local wezterm = require "wezterm"

local config = wezterm.config_builder()

config.color_scheme = "Catppuccin Mocha"

config.font = wezterm.font_with_fallback {
  {
    family = "PragmataPro Liga",
    harfbuzz_features = { "ss13", "ss15" },
  },
}
config.font_size = 16
config.cell_width = 1.04

config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false

config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }

wezterm.on("update-right-status", function(window, _)
  window:set_right_status(wezterm.format {
    { Text = window:active_workspace() },
  })
end)

-- Equivalent to POSIX basename(3)
-- Given "/foo/bar" returns "bar"
-- Given "c:\\foo\\bar" returns "bar"
local function basename(s)
  return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

wezterm.on("format-tab-title", function(tab)
  local title = " "
    .. tab.tab_index
    .. ": "
    .. basename(tab.active_pane.foreground_process_name)
    .. " "
    .. (tab.is_active and "*" or "-")
    .. " "

  return title
end)

local function SwitchToWorkspace()
  return wezterm.action_callback(function(window, pane)
    local pfile = assert(io.popen("zoxide query --list", "r"))
    local paths = pfile:read "*a"
    pfile:close()

    local choices = {}
    for label in string.gmatch(paths, "[^%s]+") do
      table.insert(choices, { label = label })
    end

    window:perform_action(
      wezterm.action.InputSelector {
        choices = choices,
        action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
          if not id and not label then
            wezterm.log_info "cancelled"
          else
            inner_window:perform_action(
              wezterm.action.SwitchToWorkspace {
                name = label:match "[^\\/]+$",
                spawn = { cwd = label },
              },
              inner_pane
            )
          end
        end),
        fuzzy = true,
      },
      pane
    )
  end)
end

config.keys = {
  { key = "o", mods = "SUPER", action = SwitchToWorkspace() },
  { key = "p", mods = "SUPER", action = wezterm.action.ShowLauncherArgs { flags = "FUZZY|WORKSPACES" } },
}

return config
