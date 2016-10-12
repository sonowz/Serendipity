--package.path = package.path .. ';data/core/lualib/?.lua;data/base/?.lua'
--require "dataloader"
--require "data.base.data" 

function getIngredients(recipe)
   local ingredients = {}
   for i,ingredient in pairs(recipe.ingredients) do
      if (ingredient.name and ingredient.amount) then
         ingredients[ingredient.name] = ingredient.amount
      elseif (ingredient[1] and ingredient[2]) then
         ingredients[ingredient[1]] = ingredient[2]
      end
   end
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
   end
   return products
end

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

function getRawIngredients(recipe, exclude)
   local raw_ingredients = {}
   for name,amount in pairs(getIngredients(recipe)) do
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
      for i,subrecipe in pairs(getRecipes(name)) do
         local subingredients = getRawIngredients(subrecipe, excluded_ingredients)
         if (subingredients.ERROR_INFINITE_LOOP) then
            loop_error = subingredients.ERROR_INFINITE_LOOP
         else
            local value = 0
            for subproduct,subamount in pairs(getProducts(subrecipe)) do
               value = value + subamount
            end

            local divisor = 0
            for subingredient,subamount in pairs(subingredients) do
               divisor = divisor + subamount
            end

            if (divisor == 0) then divisor = 1 end

            table.insert(subrecipes, {recipe = subrecipe, ingredients = subingredients, value = value / divisor})
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

         local multiple = 0
         for subname,subamount in pairs(getProducts(best_recipe.recipe)) do
            multiple = multiple + subamount
         end

         for subname,subamount in pairs(best_recipe.ingredients) do
            if (raw_ingredients[subname]) then
               raw_ingredients[subname] = raw_ingredients[subname] + amount * subamount / multiple
            else
               raw_ingredients[subname] = amount * subamount / multiple
            end
         end 
      end
   end

   return raw_ingredients   
end

function round(num, idp)
  return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end

