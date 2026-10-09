hl.config({
  input = {
    kb_layout = "us",
    kb_variant = "",
    kb_model = "",
    kb_options = "",
    kb_rules = "",
    follow_mouse = 1,
    accel_profile = "flat",
    sensitivity = 0,
    repeat_rate = 35,
    repeat_delay = 220,
    touchpad = {
      natural_scroll = true,
    },
  },
})

-- Exact device names are required; set this for your laptop when needed.
local touchpad = os.getenv("HYPR_TOUCHPAD_NAME")
if touchpad and touchpad ~= "" then
  hl.device({ name = touchpad, accel_profile = "adaptive" })
end

-- Touchpad gestures
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "up", action = "fullscreen" })
hl.gesture({ fingers = 4, direction = "down", action = "special", workspace_name = "term" })
