require("total-raw")
require("science-pack")
require("devutil")
require("classes.IngredientCost")
require("classes.RecipeRequirement")

-- main TODOs
-- preprocess recipes (remove too cheap/expensive)
-- auto sync mod setting mismatch (currently seems impossible)
-- detect infinite loops and get out
-- sort data.raw to ensure deterministic behavior

-- Configs
-- auto seed randomization (use map seed?) (seems hard)
-- strict generation mode (no extras compensation)
-- generate 2 recipes (this is needed for big mods)

total_raw.use_expensive_recipe = settings.startup["serendipity-expensive-recipe"].value

-- Use 'configs' rather than native 'settings'
configs = {
  difficulty = 1
}

item_names = {} -- array of item names
recipes_of_item = {} -- table of (item name) -> (recipes)
cost_of_recipe = {}  -- table of (recipe name) -> (recipe raw cost)

resources = {} -- 'iron ore', 'coal', ...
resource_weights = {} -- 'iron ore': 50, 'crude oil': 1, ...
science_pack_meta = {} -- science pack metadata

resources_whitelist = {"raw-wood"}
resources_blacklist = {}

function init_tables(recipes)
  -- resources
  local blacklist_set = {}
  for _, blacklist in pairs(resources_blacklist) do
    blacklist_set[blacklist] = true
  end
  for _, whitelist in pairs(resources_whitelist) do
    table.insert(resources, whitelist)
    resource_weights[whitelist] = 50
  end
  for _, resource_metadata in pairs(data.raw.resource) do
    local resource = resource_metadata.name
    if not blacklist_set[resource] and not resource_weights[resource] then
      table.insert(resources, resource)
      -- 50x fluid == 1x ore
      if resource_metadata.category == "water" or resource_metadata.category == "basic-fluid"
            or resource == "uranium-ore" then
        resource_weights[resource] = 1
      else
        resource_weights[resource] = 50
      end
    end
  end

  -- recipes_of_item
  local contained_items = {}
  for recipename, recipe in pairs(recipes) do
    for product, _ in pairs(getProducts(recipe)) do
      if not contained_items[product] and check_valid_item(product) then
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
    local result = getRawIngredients(recipe, exclude, recipes_of_item, resource_weights)
    if (result.ERROR_INFINITE_LOOP) then
      result = {
        ingredients = getIngredients(recipe),
        depth = 1
      }
    end
    -- Add depth to cost
    result.ingredients["depth"] = result.depth
    cost_of_recipe[recipename] = result.ingredients
  end

  -- science_packs
  science_pack_meta = get_base_science_pack_meta()
end

function init_configs()
  difficulty_table = {
    ["0.5x"] = 0,
    ["1x"] = 1,
    ["2x"] = 2,
    ["4x"] = 3
  }
  configs.difficulty = difficulty_table[settings.startup["serendipity-difficulty"].value]
end


function insert_all_items(tbl, recipe)
  if recipe.result then
    if check_valid_item(recipe.result) then
      table.insert(tbl, recipe.result)
    end
  end
  if recipe.results then
    for _, product in pairs(recipe.results) do
      if check_valid_item(product.name) then
        table.insert(tbl, product.name)
      end
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
  for pack_name, _ in pairs(science_pack_meta) do
    for i, item in pairs(filtered_items) do
      if item == pack_name then
        table.remove(filtered_items, i)
      end
    end
  end

  -- Stores science packs to exclude from candidates
  local recipe_requires = {}
  for _, tech in pairs(data.raw.technology) do
    local packs_set = {}
    -- Note: these variables are different from what factorio API doc says
    for _, ing in pairs(tech.unit.ingredients) do
      local pack = ing[1]
      packs_set[pack] = true
      if science_pack_meta[pack] and science_pack_meta[pack].depends then
        for _, dependent in pairs(science_pack_meta[pack].depends) do
          packs_set[dependent] = true
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
  for pack_name, _ in pairs(science_pack_meta) do
    pack_to_candidates[pack_name] = {}
  end
  for _, item_name in pairs(filtered_items) do
    for pack, _ in pairs(science_pack_meta) do
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


-- Return if this item can be science pack ingredient
function check_valid_item(name)
  -- TODO: more validity check
  local p_item = data.raw.item[name]
  if not p_item or not p_item.flags then
    return true
  else
    for _, flag in pairs(p_item.flags) do
      if flag == "hidden" then
        return false
      end
    end
  end
  return true
end


-- fix science pack picking
function get_random_items(num, candidates)
  local items = {}
  for i = 1,num,1 do
    while true do
      local rand_index = math.ceil(rand() * #candidates)
      local item = candidates[rand_index]
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


function one_or_less_fluid(ingredients)
  local fluid_count = 0
  for _, ingredient in pairs(ingredients) do
    if data.raw.fluid[ingredient] then
      fluid_count = fluid_count + 1
    end
  end
  return fluid_count <= 1
end


-- 'science_pack_recipe' should refer to data.raw
function set_ingredients(requirement, selected_resources, science_pack_recipe, candidates)
  local pack_count = 1
  local final_ingredients = {}
  local has_fluid = false
  local ingredients_count = math.min(#science_pack_recipe.ingredients, 4) -- TODO: do preprocess and remove limit
  while true do
    local ingredients = get_random_items(ingredients_count, candidates)
    while not one_or_less_fluid(ingredients) do
      ingredients = get_random_items(ingredients_count, candidates)
    end
    flog(table.tostring(ingredients))
    local costs = {}
    local partial_fit_fail = 0
    for i, ingredient in ipairs(ingredients) do
      local recipename = recipes_of_item[ingredient][1].name -- TODO: fix
      costs[i] = IngredientCost:new(selected_resources, cost_of_recipe[recipename])
      if not requirement:partial_fit(costs[i]) then
        partial_fit_fail = partial_fit_fail + 1
      end
    end
    
    if partial_fit_fail <= 1 then
      local fit_result = requirement:total_fit(costs)
      if fit_result then
        flog(costs)
        flog(requirement.min_req)
        flog(fit_result)
        pack_count = fit_result.pack_count
        local amounts = fit_result.ing_counts
        for i, ingredient in ipairs(ingredients) do
          local item_type = "item"
          if data.raw.fluid[ingredient] then
            item_type = "fluid"
            has_fluid = true
          end
          table.insert(final_ingredients, {
            name=ingredient,
            type=item_type,
            amount=amounts[i] or 1
          })
        end
        break
      end
    end
  end
  science_pack_recipe.energy_required = science_pack_recipe.energy_required * pack_count / (science_pack_recipe.result_count or 1)
  science_pack_recipe.result_count = pack_count
  science_pack_recipe.ingredients = final_ingredients
  if has_fluid then
    science_pack_recipe.category = "crafting-with-fluid"
  else
    science_pack_recipe.category = "crafting"
  end
end


function main()
  randseed(settings.startup["serendipity-randomseed"].value % 2147483647)

  init_configs()

  init_tables(data.raw.recipe)

  local pack_to_candidates = {}
  generate_filtered_recipes(pack_to_candidates)

  -- Add time to resource_weights
  local resource_weights_t = {time = 0}
  for k, v in pairs(resource_weights) do resource_weights_t[k] = v end

  -- Sort science pack for deterministic behavior
  local science_packs = {}
  for name, _ in pairs(science_pack_meta) do table.insert(science_packs, name) end
  table.sort(science_packs)

  for _, science_pack_name in ipairs(science_packs) do
    flog("Find ingredients: "..science_pack_name)
    if recipes_of_item[science_pack_name] then
      local requirement = RecipeRequirement.new()
      requirement.resource_weights = resource_weights_t
      requirement.difficulty = configs.difficulty
      --requirement.strict_mode = configs.strict_mode

      local pack_recipename = recipes_of_item[science_pack_name][1].name -- TODO: fix
      local pack_cost = IngredientCost:new(resources, cost_of_recipe[pack_recipename])
      local cost_muiltiplier = math.pow(2, configs.difficulty - 1) -- Same as settings value
      pack_cost = pack_cost:mul(cost_muiltiplier)
      requirement.min_req = pack_cost

      local candidates = pack_to_candidates[science_pack_name]
      set_ingredients(requirement, resources, data.raw.recipe[pack_recipename], candidates)
    end
  end
end

main()
