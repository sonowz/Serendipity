require("total_raw")
require("devutil")
require("classes.IngredientCost")
require("classes.RecipeRequirement")

-- main TODOs
-- preprocess recipes (remove too cheap/expensive, filter non-craftable, tech restriction)
-- maximum requirement
-- auto setting sync
-- force override setting? in desync message

-- Configs
-- auto seed randomization (use map seed?) (seems hard)
-- use resources unincluded in pack recipe (might error)
-- difficulty (0.5x, 1x, 2x, ...)

total_raw.use_expensive_recipe = settings.startup["serendipity-expensive-recipe"].value

item_names = {} -- array of item names
recipe_of_item = {} -- table of (item name) -> (recipe)
cost_of_recipe = {}  -- table of (recipe name) -> (recipe raw cost)
resources = {} -- 'iron ore', 'coal', ...

resources_blacklist = {}

function init_tables(recipes)
  -- recipe_of_item
  local contained_items = {}
  for recipename, recipe in pairs(recipes) do
    for product, _ in pairs(getProducts(recipe)) do
      if not contained_items[product] then
        contained_items[product] = true
        table.insert(item_names, product)
      end
      if not recipe_of_item[product] then
        recipe_of_item[product] = {}
      end
      table.insert(recipe_of_item[product], recipe)
    end
  end
  -- cost_of_recipe
  for recipename, recipe in pairs(recipes) do
    local exclude = {}
    for product,amount in pairs(getProducts(recipe)) do
      exclude[product] = true
    end
    local ingredients = getRawIngredients(recipe, exclude, recipe_of_item)
    if (ingredients.ERROR_INFINITE_LOOP) then
      ingredients = getIngredients(recipe)
    end
    cost_of_recipe[recipename] = ingredients
  end

  --resources
  local contained_resources = {}
  for _, resource in ipairs(resources_blacklist) do
    contained_resources[resource] = true
  end
  for _, costs in pairs(cost_of_recipe) do
    if costs then
      for resource, _ in pairs(costs) do
        if not contained_resources[resource] then
          contained_resources[resource] = true
          table.insert(resources, resource)
        end
      end
    end
  end
  --flog(resources)
  --flog(cost_of_recipe)
end


-- TODO: fix >1 fluid
-- fix science pack picking
function getRandomItems(num)
  local items = {}
  for i = 1,num,1 do
    while true do
      local item = item_names[math.random(#item_names)]
      local fail = false
      for j = 1,i-1,1 do
        if items[j] == item then
          fail = true
          break
        end
      end
      if not fail then
        table.insert(items, item)
        break
      end
    end
  end
  return items
end


function set_ingredients(requirement, selected_resources, science_pack_recipe)	
  local final_ingredients = {}
  local has_fluid = false
  while true do
    local ingredients = getRandomItems(3)
    flog("loop start")
    flog(table.tostring(ingredients))
    local costs = {}
    -- TODO: consider multiple amount recipe
    for i, ingredient in ipairs(ingredients) do
      local recipename = recipe_of_item[ingredient][1].name -- TODO: fix
      costs[i] = IngredientCost:new(selected_resources, cost_of_recipe[recipename])
    end
    
    local amounts = requirement:total_fit(costs)
    local str = ""
    if amounts then str = table.tostring(amounts) else str = "nil" end
    flog(amounts)
    if amounts then
      for i, ingredient in ipairs(ingredients) do
        local item_type = "item"
        if data.raw.fluid[ingredient] then
          item_type = "fluid"
          has_fluid = true
        end
        table.insert(final_ingredients, {
          name=ingredient,
          type=item_type,
          amount=amounts[i]
        })
      end
      break
    end
  end
  science_pack_recipe.ingredients = final_ingredients
  if has_fluid then
    science_pack_recipe.category = "crafting-with-fluid"
  else
    science_pack_recipe.category = "crafting"
  end
end


function main()
  math.randomseed(settings.startup["serendipity-randomseed"].value)

  -- TODO: fix
  selected_resources = {
    "copper-ore",
    "iron-ore",
    "stone",
    "raw-wood",
    "crude-oil",
    "coal",
    "uranium-ore"
  }

  science_packs = {}
  for _, item in pairs(data.raw.tool) do
    if item.subgroup and item.subgroup == "science-pack" then
      table.insert(science_packs, item.name)
    end
  end
  -- TODO: make science_packs ordered to be deterministic
  
  for _, science_pack_name in ipairs(science_packs) do
    flog("Find ingredients: "..science_pack_name)
    local requirement = RecipeRequirement.new()
    if recipe_of_item[science_pack_name] then
      local pack_recipename = recipe_of_item[science_pack_name][1].name -- TODO: fix
      local pack_cost = IngredientCost:new(selected_resources, cost_of_recipe[pack_recipename])
      requirement.min_req = pack_cost

      set_ingredients(requirement, selected_resources, data.raw.recipe[pack_recipename])
    end
  end
end


init_tables(data.raw.recipe)
main()
--bobmods.lib.recipe.replace_ingredient ("science-pack-1", "copper-plate", "electronic-circuit")
--bobmods.lib.recipe.replace_ingredient ("science-pack-1", "electronic-circuit", getRandomItem())

