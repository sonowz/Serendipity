require("constants")
require("gui")
require("devutil")

script.on_init(function()
  global.serendipity_configs = {
    randomseed = tostring(settings.startup["serendipity-randomseed"].value),
    ["expensive-recipe"] = tostring(settings.startup["serendipity-expensive-recipe"].value),
    difficulty = tostring(settings.startup["serendipity-difficulty"].value),
    -- TODO: enable this setting after infinite loop detection is implemented
    --["strict-mode"] = tostring(settings.startup["serendipity-strict-mode"].value)
  }

  local recipes = game.forces.player.recipes
  global.temp_ingredients = recipes["science-pack-3"].ingredients
end)

script.on_configuration_changed(function()
  local recipe_changed = true

  local changed_settings = {}
  for name, value in pairs(global.serendipity_configs) do
    if tostring(settings.startup["serendipity-"..name].value) ~= value then
      changed_settings[name] = value
    end
    flog("Different setting detected")
  end
  local recipes = game.forces.player.recipes
  if not table.deepcompare(global.temp_ingredients, recipes["science-pack-3"].ingredients) then
    recipe_changed = true
    flog("Different recipe detected")
  end

  if changed_settings ~= {} then
    for _, player in pairs(game.forces.player.players) do
      gui_different_setting_error(player.gui, changed_settings)
    end
  end

  -- TODO: Add different recipe error
  -- Continue anyway | Quit
end)
