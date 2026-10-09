hl.config({
  general = {
    gaps_in = 10,
    gaps_out = 20,
    gaps_workspaces = 0,
    border_size = 2,
    ["col.active_border"] = "rgba(cba6f7ff)",
    ["col.inactive_border"] = "rgba(313244ff)",
    resize_on_border = true,
    allow_tearing = false,
    layout = "dwindle",
  },
  decoration = {
    rounding = 4,
    rounding_power = 2,
    active_opacity = 0.97,
    inactive_opacity = 0.85,
    fullscreen_opacity = 1,
    shadow = {
      enabled = false,
    },
    blur = {
      enabled = true,
      size = 8,
      passes = 3,
      ignore_opacity = true,
      new_optimizations = true,
      vibrancy = 0,
    },
  },
  animations = {
    enabled = false,
  },
  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo = true,
    animate_manual_resizes = false,
    animate_mouse_windowdragging = false,
    focus_on_activate = true,
    vrr = 1,
  },
})
