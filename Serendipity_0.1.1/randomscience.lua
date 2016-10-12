
function getRandomRecipe(subgroup)
	math.randomseed(1253634)	--should make random seed

	local n = 0
	for recipename,recipe in pairs(table) do
		n = n + 1
	end
	local r = math.random(n)

	n = 0
	for recipename,recipe in pairs(table) do
		if n == r then
			return recipename
		end
		n = n + 1
	end
end

bobmods.lib.replace_recipe_item ("science-pack-1", "copper-plate", "electronic-circuit")
bobmods.lib.replace_recipe_item ("science-pack-1", "electronic-circuit", getRandomRecipe(data.raw.recipe))
