require("modules/monitors")
require("modules/autostart")
require("modules/environment")
require("modules/look")
require("modules/layouts")
require("modules/inputs")
require("modules/binds")
require("modules/rules")
require("modules/cs2-vulkan-fix")


-- For Noctalia Color templates
if package.searchpath("noctalia", package.path) then
  local ok, theme = pcall(require, "noctalia")
  if ok and type(theme) == "table" and type(theme.apply_theme) == "function" then
    theme.apply_theme()
  end
end

-- For Noctalia Color templates
require("noctalia").apply_theme()
