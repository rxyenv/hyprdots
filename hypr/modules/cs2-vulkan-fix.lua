-- Optional plugin: provide an ABI-compatible .so via CSGO_VULKAN_FIX_PLUGIN.
local path = os.getenv("CSGO_VULKAN_FIX_PLUGIN")
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
