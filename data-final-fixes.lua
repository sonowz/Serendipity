require("total-raw")
require("devutil")
require("classes.IngredientCost")
require("classes.RecipeRequirement")

-- main TODOs
-- preprocess recipes (remove too cheap/expensive)
-- maximum requirement
-- auto setting sync
-- force override setting? in desync message

-- Configs
-- auto seed randomization (use map seed?) (seems hard)
-- use resources unincluded in pack recipe (might error)
-- difficulty (0.5x, 1x, 2x, ...)

total_raw.use_expensive_recipe = settings.startup["serendipity-expensive-recipe"].value

item_names = {} -- array of item names
recipes_of_item = {} -- table of (item name) -> (recipes)
cost_of_recipe = {}  -- table of (recipe name) -> (recipe raw cost)

resources = {} -- 'iron ore', 'coal', ...
science_packs = {} -- 'science-pack-1', ...

resources_whitelist = {"raw-wood"}
resources_blacklist = {}

function init_tables(recipes)
  -- recipes_of_item
  local contained_items = {}
  for recipename, recipe in pairs(recipes) do
    for product, _ in pairs(getProducts(recipe)) do
      if not contained_items[product] then
        contained_items[product] = true
        table.insert(item_names, product)
      end
      if not recipes_of_item[product] then
        recipes_of_item[product] = {}
      end
      table.insert(recipes_of_item[product], recipe)
    end
  end

  -- cost_of_recipe
  for recipename, recipe in pairs(recipes) do
    local exclude = {}
    for product,amount in pairs(getProducts(recipe)) do
      exclude[product] = true
    end
    local ingredients = getRawIngredients(recipe, exclude, recipes_of_item)
    if (ingredients.ERROR_INFINITE_LOOP) then
      ingredients = getIngredients(recipe)
    end
    cost_of_recipe[recipename] = ingredients
  end

  -- resources
  local resources_set = {}
  local blacklist_set = {}
  for _, blacklist in pairs(resources_blacklist) do
    blacklist_set[blacklist] = true
  end
  for _, whitelist in pairs(resources_whitelist) do
    table.insert(resources, whitelist)
    resources_set[whitelist] = true
  end
  for _, resource_metadata in pairs(data.raw.resource) do
    local resource = resource_metadata.name
    if not blacklist_set[resource] and not resources_set[resource] then
      table.insert(resources, resource)
    end
  end

  -- science_packs
  -- Dynamic version
  --[[
  science_packs = {}
  for _, item in pairs(data.raw.tool) do
    if item.subgroup and item.subgroup == "science-pack" then
      table.insert(science_packs, item.name)
    end
  end
  table.sort(science_packs) -- Required to make recipe deterministic
  --]]
  -- Static version
  science_packs = {
    "science-pack-1", 
    "science-pack-2", 
    "science-pack-3", 
    "military-science-pack",
    "production-science-pack",
    "high-tech-science-pack"
  }
  table.sort(science_packs) -- Required to make recipe deterministic
end


function insert_all_items(tbl, recipe)
  if recipe.result then
    table.insert(tbl, recipe.result)
  end
  if recipe.results then
    for _, product in pairs(recipe.results) do
      table.insert(tbl, product.name)
    end
  end
end


-- Returns 'science_pack': 'item candidates'
function generate_filtered_recipes(pack_to_candidates)
  -- TODO: filter recipes
  local filtered_recipes = data.raw.recipe

  local filtered_items = {}
  for _, recipe in pairs(filtered_recipes) do
    insert_all_items(filtered_items, recipe)
  end
  filtered_items = table.unique(filtered_items)

  -- Filter science packs
  for _, pack in pairs(science_packs) do
    for i, item in pairs(filtered_items) do
      if item == pack then
        table.remove(filtered_items, i)
      end
    end
  end

  -- TODO: find a way to generate this dynamically
  local science_pack_depends = {
    ["science-pack-1"] = {},
    ["science-pack-2"] = {"science-pack-1"},
    ["science-pack-3"] = {"science-pack-1", "science-pack-2"},
    ["military-science-pack"] = {"science-pack-1", "science-pack-2"},
    ["production-science-pack"] = {"science-pack-1", "science-pack-2", "science-pack-3"},
    ["high-tech-science-pack"] = {"science-pack-1", "science-pack-2", "science-pack-3"},
  }

  -- Stores science packs to exclude from candidates
  local recipe_requires = {}
  for _, tech in pairs(data.raw.technology) do
    local packs_set = {}
    -- Note: these variables are different from what factorio API doc says
    for _, ing in pairs(tech.unit.ingredients) do
      local pack = ing[1]
      packs_set[pack] = true
      if science_pack_depends[pack] then
        for _, dependant in pairs(science_pack_depends[pack]) do
          packs_set[dependant] = true
        end
      end
    end
    if tech.effects then
      for _, modifier in pairs(tech.effects) do
        if modifier.type == "unlock-recipe" then
          -- What if same recipe is unlocked in different techs? Possible bad luck.
          recipe_requires[modifier.recipe] = packs_set
        end
      end
    end
  end

  local item_requires = {}
  for _, item_name in pairs(item_names) do
    -- TODO: better minimal pack algorithm
    local min_requires = recipe_requires[(recipes_of_item[item_name][1]).name]
    if min_requires then
      for _, recipe in pairs(recipes_of_item[item_name]) do
        local requires = recipe_requires[recipe.name]
        if #requires < #min_requires then
          min_requires = requires
        end
      end
    end
    item_requires[item_name] = min_requires
  end
    
  -- TODO: improvement in recipe -> item?
  for _, pack in pairs(science_packs) do
    pack_to_candidates[pack] = {}
  end
  for _, item_name in pairs(filtered_items) do
    for _, pack in pairs(science_packs) do
      if not item_requires[item_name] then -- It is unlocked from start
        -- TODO: basic filter of non-craftable
        -- Needs thorough filtering of items & recipes from beginning of the mod
        if recipes_of_item[item_name] then
          for _, recipe in ipairs(recipes_of_item[item_name]) do
            if recipe.enabled == nil or recipe.enabled == true then
              table.insert(pack_to_candidates[pack], item_name)
              break
            end
          end
        end
      elseif not item_requires[item_name][pack] then -- Tech tree validated
        table.insert(pack_to_candidates[pack], item_name)
      end
    end
  end
  pack_to_candidates = table.unique(pack_to_candidates)
end


-- TODO: fix >1 fluid
-- fix science pack picking
function get_random_items(num, candidates)
  local items = {}
  for i = 1,num,1 do
    while true do
      local item = candidates[math.random(#candidates)]
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


-- 'science_pack_recipe' should refer to data.raw
function set_ingredients(requirement, selected_resources, science_pack_recipe, candidates)	
  local final_ingredients = {}
  local has_fluid = false
  while true do
    local ingredients = get_random_items(3, candidates)
    flog("loop start")
    flog(table.tostring(ingredients))
    local costs = {}
    -- TODO: consider multiple amount recipe
    for i, ingredient in ipairs(ingredients) do
      local recipename = recipes_of_item[ingredient][1].name -- TODO: fix
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
  
  init_tables(data.raw.recipe)

  local pack_to_candidates = {}
  generate_filtered_recipes(pack_to_candidates)

  for _, science_pack_name in ipairs(science_packs) do
    flog("Find ingredients: "..science_pack_name)
    local requirement = RecipeRequirement.new()
    if recipes_of_item[science_pack_name] then
      local pack_recipename = recipes_of_item[science_pack_name][1].name -- TODO: fix
      local pack_cost = IngredientCost:new(resources, cost_of_recipe[pack_recipename])
      requirement.min_req = pack_cost

      local candidates = pack_to_candidates[science_pack_name]
      set_ingredients(requirement, resources, data.raw.recipe[pack_recipename], candidates)
    end
  end
end



main()
--bobmods.lib.recipe.replace_ingredient ("science-pack-1", "copper-plate", "electronic-circuit")
--bobmods.lib.recipe.replace_ingredient ("science-pack-1", "electronic-circuit", getRandomItem())

