-- Original source by: (this is modified version)
-- https://forums.factorio.com/viewtopic.php?f=6&t=4397
-- author: DaveMcW 


--package.path = package.path .. ';data/core/lualib/?.lua;data/base/?.lua'
--require "dataloader"
--require "data.base.data" 
require("devutil")

total_raw = {}
total_raw.use_expensive_recipe = false

function getIngredients(recipe)
  local ingredients = {}
  if recipe.ingredients then
    for i,ingredient in pairs(recipe.ingredients) do
      if (ingredient.name and ingredient.amount) then
        ingredients[ingredient.name] = ingredient.amount
      elseif (ingredient[1] and ingredient[2]) then
        ingredients[ingredient[1]] = ingredient[2]
      end
    end
  elseif recipe.normal then
    if total_raw.use_expensive_recipe and recipe.expensive then
      return getIngredients(recipe.expensive)
    else
      return getIngredients(recipe.normal)
    end
  end
  -- Add time to ingredients
  ingredients['time'] = recipe.energy_required or 0.5 -- Default is 0.5

  return ingredients
end

function getProducts(recipe)
  local products = {}
  if (recipe.results) then
    for i,product in pairs(recipe.results) do
      if (product.name and product.amount) then
        products[product.name] = product.amount
      end
    end
  elseif (recipe.result) then
    local amount = 1
    if (recipe.result_count) then
      amount = recipe.result_count
    end
    products[recipe.result] = amount
  elseif recipe.normal then
    if total_raw.use_expensive_recipe and recipe.expensive then
      return getProducts(recipe.expensive)
    else
      return getProducts(recipe.normal)
    end
  end
  return products
end

-- Original function
--[[
function getRecipes(item)
   local recipes = {}
   for i,recipe in pairs(data.raw.recipe) do
    local products = getProducts(recipe)
    for product,amount in pairs(products) do
     if (product == item) then
      table.insert(recipes, recipe)
     end
    end
   end
   return recipes
end
--]]

-- Used for memoization of getRawIngredients() result
recipe_cache = {}

function getRawIngredients(recipe, exclude, recipes_of_item, resource_set)
  local raw_ingredients = {}
  local max_depth = 1
  for name,amount in pairs(getIngredients(recipe)) do
    -- Check if the ingredient is resource
    if resource_set[name] then
      if (raw_ingredients[name]) then
        raw_ingredients[name] = raw_ingredients[name] + amount
      else 
        raw_ingredients[name] = amount
      end
    else
      -- Do not use an item as its own ingredient 
      if (exclude[name]) then
        return {ERROR_INFINITE_LOOP = name}
      end
      local excluded_ingredients = {[name] = true}
      for k,v in pairs(exclude) do
        excluded_ingredients[k] = true
      end

      -- Recursively find the sub-ingredients for each ingredient
      -- There might be more than one recipe to choose from
      local subrecipes = {}
      local loop_error = nil
      if recipes_of_item[name] then
        for i,subrecipe in pairs(recipes_of_item[name]) do
          -- Fetch memoized rawIngredients if possible
          local result = nil
          if recipe_cache[subrecipe.name] then
            result = recipe_cache[subrecipe.name]
          else
            result = getRawIngredients(subrecipe, excluded_ingredients, recipes_of_item, resource_set)
          end
          if (result.ERROR_INFINITE_LOOP) then
            loop_error = result.ERROR_INFINITE_LOOP
          else
            local subingredients = result.ingredients
            local depth = result.depth
            local value = 0
            for subproduct,subamount in pairs(getProducts(subrecipe)) do
              value = value + subamount
            end

            local divisor = 0
            for subingredient,subamount in pairs(subingredients) do
              divisor = divisor + subamount
            end

            if (divisor == 0) then divisor = 1 end

            table.insert(subrecipes, {recipe = subrecipe, ingredients = subingredients, value = value / divisor, depth = depth})
          end
        end
      end

      if (#subrecipes == 0) then
        if (loop_error and loop_error ~= name) then
          -- This branch of the recipe tree is invalid
          return {ERROR_INFINITE_LOOP = loop_error}
        else
          -- This is a raw resource
          if (raw_ingredients[name]) then
            raw_ingredients[name] = raw_ingredients[name] + amount
          else 
            raw_ingredients[name] = amount
          end
        end
      else
        -- Pick the cheapest recipe
        local best_recipe = nil
        local best_value = 0
        for i,subrecipe in pairs(subrecipes) do
          if (best_value < subrecipe.value) then
            best_value = subrecipe.value
            best_recipe = subrecipe
          end
        end

        if best_recipe then
          local multiple = 0
          for subname,subamount in pairs(getProducts(best_recipe.recipe)) do
            multiple = multiple + subamount
          end

          local best_recipe_ingredients = best_recipe.ingredients
          if best_recipe.normal then
            if total_raw.use_expensive_recipe and best_recipe.expensive then
              best_recipe_ingredients = best_recipe.expensive.ingredients
            else
              best_recipe_ingredients = best_recipe.normal.ingredients
            end
          end
          for subname,subamount in pairs(best_recipe_ingredients) do
            if (raw_ingredients[subname]) then
              raw_ingredients[subname] = raw_ingredients[subname] + amount * subamount / multiple
            else
              raw_ingredients[subname] = amount * subamount / multiple
            end
          end

          max_depth = math.max(max_depth, best_recipe.depth + 1)
        end
      end
    end
  end

  local return_value = {
    ingredients = raw_ingredients,
    depth = max_depth
  }   
  recipe_cache[recipe.name] = return_value -- Memoize
  return return_value
end

function round(num, idp)
  return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end

-- Original main loop
--[[
for recipename,recipe in pairs(data.raw.recipe) do
   local exclude = {}
   for product,amount in pairs(getProducts(recipe)) do
    exclude[product] = true
   end
   local ingredients = getRawIngredients(recipe, exclude)
   if (ingredients.ERROR_INFINITE_LOOP) then
    ingredients = getIngredients(recipe)
   end
   print("[u]" .. recipename .. "[/u]")
   for name,amount in pairs(ingredients) do
    print(round(amount, 1) .. "x " .. name)
   end
   print ""
end
--]]
