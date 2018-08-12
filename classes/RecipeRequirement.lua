-- RecipeRequirement class

require("IngredientCost")
local matrix = require("matrix")

RecipeRequirement = {}
RecipeRequirement.__index = RecipeRequirement


function RecipeRequirement:new()
  local obj = {}
  obj.min_req = nil -- IngredientCost class
  obj.weight = nil  -- IngredientCost class
  obj.resource_weight = 1.0 -- don't need to change
  obj.max_req_resource = 0.0 -- max resource cost sum (iron, copper, ...)
  obj.max_req_total = 0.0    -- max total cost sum (resource, time, depth)
                             -- depth = average depth among ingredients
  obj.tech_req = {} -- list of science packs (TODO: blacklist or whitelist?)
  obj.max_ingredient_count = 5 -- max possible count of ingredient (ex: 5x iron plate) 
  obj.configs = {}  -- config object in 'data-final-fixes.lua'
  return setmetatable(obj, RecipeRequirement)
end


-- Check if one ingredient satisfies individual requirement
function RecipeRequirement:partial_fit(ing_cost)
  -- currently only check depth
  -- depth does not change even considering multiple count (ex: 2x iron plate)
  local global_min_depth = self.configs.difficulty + 1
  local recipe_max_depth = self.min_req.depth
  return math.min(global_min_depth, recipe_max_depth) <= ing_cost.depth
end


RecipeRequirement._find_min_count = {}

-- Check if linear combination of ingredients satisfy requirement
function RecipeRequirement:total_fit(ing_costs)
  return self:_find_min_count(ing_costs)
end


-- Check if min_req_mat <= cost_mat <= max_req_mat
function RecipeRequirement:_check_fit(min_req_mat, max_req_mat, cost_mat)
  local min_req = min_req_mat[1]
  local max_req = max_req_mat[1]
  local cost = cost_mat[1]
  local dimension = #cost
  for i = 1, dimension do
    if not (min_req[i] <= cost[i] and cost[i] <= max_req[i]) then
      return nil -- Fail
    end
  end
  -- If fit, return 'pack_count' which makes normalized least square
  for i = 1, dimension do
    if min_req[i] ~= 0.0 then
      cost[i] = cost[i] / min_req[i]
    else -- TODO: adjust cost which does not appear in original pack
      cost[i] = -100
    end
  end
  local least_squares = {}
  for i = 1, self.max_ingredient_count do
    local least_square = 0.0
    for j = 1, dimension do
      if cost[j] >= 0.0 then
        least_square = least_square + (i - cost[j]) * (i - cost[j])
      end
    end
    table.insert(least_squares, least_square)
  end
  local index, min_ls = 1, least_squares[1]
  for i, least_square in pairs(least_squares) do
    if least_square < min_ls then
      index = i
      min_ls = least_square
    end
  end
  return index -- Best science pack count
end


-- Find minimum count for ingredients
-- Same as solving linear system 'r <= ax + by + cz + ... <= nr' for integer 1 <= a,b,c <= n
--                               where 'r' is 'min_req', x,y,z is 'ing_costs',
--                                     'n' is 'self.max_ingredient_count'
function RecipeRequirement:_find_min_count(ing_costs)
  -- Make min_req('r'), max_req('nr') vector
  local ing_keys = ing_costs[1]:keys(true) -- no_depth, depth was considered in partial_fit()
  local min_req = self.min_req:toarray(ing_keys)
  min_req = matrix:new({min_req})
  local max_req = matrix.mulnum(min_req, self.max_ingredient_count)

  -- Make ing_cost vectors
  local ing_mats = {}
  for _, ing_cost in pairs(ing_costs) do
    table.insert(ing_mats, matrix:new({ing_cost:toarray(ing_keys)}))
  end

  -- fitting_cost: ax + by + cz + ...
  local ing_counts = {}; -- {1, 1, 1, ..}
  local fitting_cost = {}; -- {0.0, 0.0, 0.0, ..} vector
  for _ = 1, #ing_costs do table.insert(ing_counts, 1) end
  for _ = 1, #ing_keys do table.insert(fitting_cost, 0.0) end
  fitting_cost = matrix:new({fitting_cost})
  for _, ing_mat in pairs(ing_mats) do
    fitting_cost = matrix.add(fitting_cost, ing_mat)
  end
  -- Here, brute-force all possible cases
  -- Number of cases: n ^ #ing_costs (at most 5^5)
  local i = 1 -- cursor
  local n = self.max_ingredient_count
  while true do
    local fit_result = self:_check_fit(min_req, max_req, fitting_cost)
    if fit_result then -- Success!
      return {ing_counts = ing_counts, pack_count = fit_result}
    end
    ing_counts[i] = ing_counts[i] + 1
    fitting_cost = matrix.add(fitting_cost, ing_mats[i])
    if ing_counts[i] > n then
      while ing_counts[i] > n do
        -- Rollback
        ing_counts[i] = 1
        fitting_cost = matrix.sub(fitting_cost, matrix.mulnum(ing_mats[i], n))
        -- Carry
        i = i + 1
        if i > #ing_costs then return nil end -- Fail!
        ing_counts[i] = ing_counts[i] + 1
        fitting_cost = matrix.add(fitting_cost, ing_mats[i])
      end
      i = 1
    end
  end
end
