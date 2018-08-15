-- RecipeRequirement class

require("IngredientCost")
local matrix = require("matrix")

RecipeRequirement = {}
RecipeRequirement.__index = RecipeRequirement


function RecipeRequirement:new()
  local obj = {}
  obj.min_req = nil -- IngredientCost class
  obj.resource_weights = nil -- List of resources and weights used in _check_fit()
                             -- This should include "time", but not "depth
  obj.difficulty = nil  -- Difficulty set by config
  obj.strict_mode = nil -- Enable strict mode, which only allows resources from original recipe
  obj.max_ingredient_count = 5 -- Max possible count of ingredient (ex: 5x iron plate) 
  return setmetatable(obj, RecipeRequirement)
end


-- Check if one ingredient satisfies individual requirement
function RecipeRequirement:partial_fit(ing_cost)
  -- Currently only check depth
  -- Depth does not change even considering multiple count (ex: 2x iron plate)
  local min_depth = math.ceil(self.min_req.depth / 2)
  local difficulty_modifier = self.difficulty

  -- Low depth adjustments to prevent infinite loop
  if self.min_req.depth <= 8 and difficulty_modifier == 3 then
    difficulty_modifier = 2
  end
  if self.min_req.depth <= 4 then
    difficulty_modifier = math.max(difficulty_modifier - 1, 0)
  end

  return min_depth + difficulty_modifier <= ing_cost.depth
end


RecipeRequirement._find_min_count = {}

-- Check if linear combination of ingredients satisfy requirement
function RecipeRequirement:total_fit(ing_costs)
  if not self:_check_depth_constraint(ing_costs) then
    return nil
  end
  return self:_try_total_fit(ing_costs)
end


-- Maximum depth of ingredients should not be greater than original maximum depth
-- (Difficulty setting leverages this constraint)
function RecipeRequirement:_check_depth_constraint(ing_costs)
  local ing_max_depth = ing_costs[1]["depth"]
  for _, ing_cost in pairs(ing_costs) do
    ing_max_depth = math.max(ing_max_depth, ing_cost["depth"])
  end
  return ing_max_depth <= self.min_req.depth + self.difficulty
end


-- Check if min_req_mat <= cost_mat <= max_req_mat
function RecipeRequirement:_check_fit(min_req_mat, max_req_mat, cost_mat, ing_weights)
  local min_req = min_req_mat[1]
  local max_req = max_req_mat[1]
  local cost = cost_mat[1]
  local dimension = #cost
  local weighted_sum = 0 -- Amount of all resources
  local deficits = 0 -- Amount of insufficient resources 
  local extras = 0   -- Amount of extra resources (completely not required ones)
  if self.strict_mode then
    for i = 1, dimension do
      if not (min_req[i] <= cost[i] and cost[i] <= max_req[i]) then
        return nil --Fail
      end
    end
  else -- Normal mode
    for i = 1, dimension do
      if max_req[i] ~= 0 and cost[i] > max_req[i] then
        return nil -- Fail
      end
      if max_req[i] == 0 then
        extras = extras + cost[i] * ing_weights[i]
      end
      if cost[i] < min_req[i] then
        deficits = deficits + (min_req[i] - cost[i]) * ing_weights[i]
      end
      weighted_sum = weighted_sum + cost[i] * ing_weights[i]
    end

    -- Extras should compensate for deficits, but not too much in total ingredients
    if not (deficits < extras * 0.3 and extras < weighted_sum * 0.3) then
      return nil -- Fail
    end
  end
  
  -- If fit, return 'pack_count' (or 'm') which makes normalized least square
  for i = 1, dimension do
    if min_req[i] ~= 0.0 and min_req[i] <= cost[i] then
      cost[i] = cost[i] / min_req[i]
    else -- Deficit resources & extra resources are not accounted
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


-- Find counts for ingredients
-- Same as solving linear system 'r <= ax + by + cz + ... <= nr' for integer 1 <= a,b,c <= n
--                               where 'r' is 'min_req', x,y,z is 'ing_costs',
--                                     'n' is 'self.max_ingredient_count'
-- The result is 'a', 'b', 'c', ..., which are amount of ingredient in science pack recipe,
-- and 1 <= m <= n where 'm' is amount of science pack produced (pack_count)
function RecipeRequirement:_try_total_fit(ing_costs)
  -- Make min_req('r'), max_req('nr') vector
  local ing_keys = {}
  local ing_weights = {}
  for r, _ in pairs(self.resource_weights) do table.insert(ing_keys, r) end -- Get resources
  for _, r in pairs(ing_keys) do table.insert(ing_weights, self.resource_weights[r]) end -- Get weights
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
    local fit_result = self:_check_fit(min_req, max_req, fitting_cost, ing_weights)
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
