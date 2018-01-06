--require("mersenne_twister_rng")
require("total_raw")

require("devutil")

function getRandomRecipe(table)
	math.randomseed(settings.startup["serendipity-randomseed"].value)

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

bobmods.lib.recipe.replace_ingredient ("science-pack-1", "copper-plate", "electronic-circuit")
bobmods.lib.recipe.replace_ingredient ("science-pack-1", "electronic-circuit", getRandomRecipe(data.raw.recipe))
