data:extend({
  {
    type = "int-setting",
    name = "serendipity-randomseed",
    setting_type = "startup",
    default_value = 1111
  },
  {
    type = "bool-setting",
    name = "serendipity-expensive-recipe",
    setting_type = "startup",
    default_value = false
  },
  {
    type = "string-setting",
    name = "serendipity-difficulty",
    setting_type = "startup",
    allowed_values = {"0.5x", "1x", "2x", "4x"},
    default_value = "1x"
  },
  -- TODO: enable this setting after infinite loop detection is implemented
  --[[
  {
    type = "bool-setting",
    name = "serendipity-strict-mode",
    setting_type = "startup",
    default_value = false
  }
  --]]
})