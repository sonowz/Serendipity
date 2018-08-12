require("constants")
require("gui")
require("devutil")

script.on_init(function()
  global.randomseed = settings.startup["serendipity-randomseed"].value

  local recipes = game.forces.player.recipes
  global.temp_ingredients = recipes["science-pack-1"].ingredients
end)

script.on_configuration_changed(function()
  local seed_changed = false
  local recipe_changed = true

  if global.randomseed ~= settings.startup["serendipity-randomseed"].value then
    seed_changed = true
    flog("Different seed detected")
  end
  local recipes = game.forces.player.recipes
  if not table.deepcompare(global.temp_ingredients, recipes["science-pack-1"].ingredients) then
    recipe_changed = true
    flog("Different recipe detected")
  end

  if seed_changed then
    for _, player in pairs(game.forces.player.players) do
      gui_different_seed_error(player.gui, global.randomseed)
    end
  end

  -- TODO: Add recipe setting
end)
