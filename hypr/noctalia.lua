-- Fresh-install fallback. Noctalia can replace the deployed local copy.
return {
  apply_theme = function()
    hl.config({ general = {
      ["col.active_border"] = "rgba(cba6f7ff)",
      ["col.inactive_border"] = "rgba(313244ff)",
    } })
  end,
}
