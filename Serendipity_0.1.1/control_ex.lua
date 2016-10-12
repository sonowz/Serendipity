
require("total_raw")
--require("randomscience")

log("hello")
print("hh")

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