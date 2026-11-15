-- Rebuild this plugin after Hyprland ABI updates. Environment overrides the local install.
local path = os.getenv("CSGO_VULKAN_FIX_PLUGIN")
if not path or path == "" then
  local home = os.getenv("HOME")
  if home then
    local installed = home .. "/.local/lib/hyprland/csgo-vulkan-fix.so"
    local file = io.open(installed, "rb")
    if file then
      file:close()
      path = installed
    end
  end
end
if path and path ~= "" then
  local quoted = "'" .. path:gsub("'", "'\"'\"'") .. "'"
  hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl plugin load " .. quoted .. " && hyprctl reload")
  end)
  if hl.plugin and hl.plugin.csgo_vulkan_fix then
    hl.plugin.csgo_vulkan_fix.vkfix_app({ app = "cs2", w = 1920, h = 1080 })
    hl.config({ plugin = { csgo_vulkan_fix = { fix_mouse = true } } })
  end
end
