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



require("classes.IngredientCost")
require("classes.RecipeRequirement")

local materials = {"iron", "copper"}
local cost1 = IngredientCost:new(materials, {1, 0, 1, 1})
local cost2 = IngredientCost:new(materials, {0, 1, 1, 1})
local cost3 = IngredientCost:new(materials, {1, 1, 1, 1})
local min_req = IngredientCost:new(materials, {5, 3, 10, 1})
local req = RecipeRequirement:new()
req.min_req = min_req
local ret = req:total_fit({cost1, cost2, cost3})
local str = ""
if ret then str = table.tostring(ret) else str = "nil" end

script.on_event(defines.events.on_player_crafted_item, function(event)
    local player = game.players[event.player_index]
    --player.print(table.tostring(global.temp_ingredients))
    --player.print(tostring(global.randomseed))
    player.print(str)
end)