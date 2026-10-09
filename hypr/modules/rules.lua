-- ── Helpers ────────────────────────────────────────────────

-- Centered floating window, size as fraction of the monitor
local function float_centered(name, match, w, h, extra)
  local rule = {
    name = name,
    match = match,
    float = true,
    center = true,
    size = { "monitor_w*" .. w, "monitor_h*" .. h },
  }
  for k, v in pairs(extra or {}) do rule[k] = v end
  hl.window_rule(rule)
end

hl.layer_rule({
  name = "no-anim-selection",
  match = { namespace = "selection" },
  no_anim = true,
})

hl.layer_rule({
  name = "noctalia",
  match = { namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$" },
  no_anim = true,
  blur = true,
  blur_popups = true,
  ignore_alpha = 0.5,
})

hl.window_rule({
  name = "noctalia-settings",
  match = { class = "^dev\\.noctalia\\.Noctalia$" },
  float = true,
  center = true,
  size = { 1080, 920 },
})

-- ── Global window behavior ─────────────────────────────────

hl.window_rule({
  name = "suppress-maximize-events",
  match = { class = ".*" },
  suppress_event = "maximize",
})

hl.window_rule({
  name = "plain-floating-windows",
  match = { float = true },
  rounding = 4,
  border_size = 1,
})

hl.window_rule({
  name = "fix-xwayland-drags",
  match = {
    class = "^$",
    title = "^$",
    xwayland = true,
    float = true,
    fullscreen = false,
    pin = false,
  },
  no_focus = true,
})

-- ── Dialogs & popups ───────────────────────────────────────

float_centered("common-dialogs",
  { title = "^(Open|Save|Save As|Choose|Select|File Upload)(.*)$" },
  0.55, 0.6)

hl.window_rule({
  name = "picture-in-picture",
  match = { title = "^(Picture-in-Picture|Picture in picture)$" },
  float = true,
  pin = true,
  size = { "monitor_w*0.28", "monitor_h*0.28" },
  move = { "monitor_w*0.7", "monitor_h*0.68" },
})

-- ── Floating apps ──────────────────────────────────────────

-- File managers / image viewer
float_centered("float-file-managers",
  { class = "^(org.gnome.Nautilus|thunar|org.gnome.LoupeD)$", fullscreen = false },
  0.6, 0.65)

-- TUI utilities (network, audio, bluetooth) + floating terminal
float_centered("float-tui-tools",
  { class = "^org\\.zen0x\\.(impala|wiremix|bluetui|floating-terminal)$" },
  0.55, 0.6)

-- btop wants room for all its boxes
float_centered("float-btop",
  { class = "^(org.zen0x.btop)$" },
  0.85, 0.85)

-- Small utility windows
float_centered("float-satty",
  { class = "^(com.gabm.satty)$", fullscreen = false },
  0.5, 0.6)
float_centered("float-android-studio-welcome",
  { class = "^(jetbrains-studio)$", title = "^Welcome to Android Studio$", fullscreen = false },
  0.45, 0.55)
float_centered("float-nwg-look",
  { class = "^(nwg-look)$", fullscreen = false },
  0.6, 0.7)

-- LocalSend: portrait floating
hl.window_rule({
  name = "float-localsend",
  match = { class = "^(localsend_app)$", fullscreen = false },
  float = true,
  center = true,
  size = { 400, 900 },
})

-- Media
float_centered("float-spotify",
  { class = "^(Spotify)$", fullscreen = false },
  0.75, 0.75)

hl.window_rule({
  name = "move-hyprland-run",
  match = { class = "hyprland-run" },
  move = { 20, "monitor_h-120" },
  float = true,
})

-- ── Steam ──────────────────────────────────────────────────

local steam_class = "^(steam|Steam|steamwebhelper)$"

hl.window_rule({
  name = "steam-floating",
  match = { class = steam_class },
  float = true,
  center = true,
  tag = "-default-opacity",
  opacity = "1 1",
  idle_inhibit = "fullscreen",
})

-- ── Scratchpads ────────────────────────────────────────────

-- Pin scratchpad apps (launched by the Super+Alt binds) to their
-- special workspace, floating and centered
for _, s in ipairs({ "term", "notes", "files", "mixer", "monitor" }) do
  hl.window_rule({
    name = "scratch-" .. s,
    match = { class = "^org\\.zen0x\\.scratch-" .. s .. "$" },
    workspace = "special:" .. s,
    float = true,
    center = true,
    size = { "monitor_w*0.65", "monitor_h*0.65" },
  })
end

-- ── Workspaces ─────────────────────────────────────────────

-- Persistent workspaces 1-5; workspace 6 is created on demand.
for i = 1, 5 do
  hl.workspace_rule({
    workspace = tostring(i),
    persistent = true,
  })
end

hl.window_rule({
  name = "float-discord",
  match = { class = "^(discord|Discord|vesktop|Vesktop)$", fullscreen = false },
  float = true,
  center = true,
  size = { "monitor_w*0.75", "monitor_h*0.8" },
  workspace = "4",
})

hl.window_rule({
  name = "float-unityhub",
  match = { class = "^(unityhub|UnityHub)$", fullscreen = false },
  float = true,
  center = true,
  size = { "monitor_w*0.7", "monitor_h*0.7" },
  workspace = "4",
})

local workspace_assignments = {
  { ws = "1", match = { class = "^(brave-origin|Brave-origin|brave-browser|Brave-browser|brave|Brave)$" } },
  { ws = "2", match = { class = "^(foot|footclient|org\\.zen0x\\.tmux|Alacritty|WezTerm|kitty)$" } },
  { ws = "3", match = { class = "^code$" } },
  { ws = "4", match = { class = "^(Spotify)$" } },
  { ws = "5", match = { class = "^(steam|Steam|heroic|Heroic)$" } },
  { ws = "6", match = { title = "^(.*\\.exe|.*game|.*Game)$" } },
}

for _, a in ipairs(workspace_assignments) do
  hl.window_rule({
    name = "ws" .. a.ws,
    match = a.match,
    workspace = a.ws,
  })
end