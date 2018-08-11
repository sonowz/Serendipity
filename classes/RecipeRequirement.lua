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
  return setmetatable(obj, RecipeRequirement)
end


-- check if one ingredient satisfies individual requirement
function RecipeRequirement:partial_fit(ing_cost)
  -- currently only check depth
  -- depth does not change even considering multiple count (ex: 2x iron plate)
  return self.min_req.depth <= ing_cost.depth
end


RecipeRequirement._find_min_count = {}

-- check if linear combination of ingredients satisfy requirement
function RecipeRequirement:total_fit(ing_costs)
  return self:_find_min_count(ing_costs)
end


-- TODO: edge cases (singular, right inverse, ...)
-- find minimum count for ingredients
-- same as solving linear system 'r <= ax + by + cz + ... <= nr' for integer 1<= a,b,c <= n
--                               where 'r' is 'min_req', x,y,z is 'ing_costs'
-- use solution of linear system '(x y z)^-1 * r <= (a b c)^t' (least squares)
-- rhs can't be determined same way, since (x y z) can be indefinite matrix
function RecipeRequirement:_find_min_count(ing_costs)
  
  -- make min_req('r') vector
  local ing_keys = ing_costs[1]:keys(true) -- no_depth, depth was considered in partial_fit()
  local min_req = self.min_req:toarray(ing_keys)
  min_req = matrix.transpose(matrix:new({min_req}))
  
  -- construct matrix (x y z)
  local mat = {}
  for i, ing_cost in ipairs(ing_costs) do
    mat[i] = ing_cost:toarray(ing_keys)
  end
  mat = matrix.transpose(matrix:new(mat))
  
  -- delete zero row (avoid singular case)
  local is_zero_vector = function (v)
    for _, x in ipairs(v) do if x ~= 0 then return false end end
    return true
  end
  local n = 1
  local temp_mat = {}
  local temp_keys = {}
  local temp_r = {}
  for i, row in ipairs(mat) do
    if not is_zero_vector(row) then
      temp_mat[n] = row
      temp_keys[n] = ing_keys[i]
      temp_r[n] = min_req[i]
      n = n + 1
    elseif min_req[i][1] ~= 0.0 then -- requirement can't be satisfied
      return nil
    end
  end
  mat = matrix:new(temp_mat)
  ing_keys = temp_keys
  min_req = matrix:new(temp_r)

  -- find left inverse
  local transpose = matrix.transpose(mat)
  local inverted = matrix.invert(transpose * mat)
  if not inverted then return nil end -- TODO: singular case
  local left_inverse = inverted * transpose

  -- (x y z)^-1 * r
  local m_r = left_inverse * min_req
  local epsilon = matrix:new(matrix.rows(m_r), matrix.columns(m_r), 1E-6) -- consider error from inverse

  -- TODO: prove '(x y z)^-1 * r <= (a b c)^t' holds when (x y z) is indefinite (maybe because a,b,c >= 1)
  -- find minimum a,b,c <= n
  local solution = {}
  for i, row in ipairs(m_r - epsilon) do
    solution[i] = math.max(math.ceil(row[1]), 1)
    -- disable to debug easily
    --if solution[i] > self.max_ingredient_count then return nil end -- TODO: make recursive call
  end
  
  -- check if solution satisfies ax + by + cz + ... <= nr
  local lhs = mat * matrix.transpose(matrix:new({solution}))
  local rhs = self.max_ingredient_count * min_req
  for _, row in ipairs(rhs - lhs) do
    for _, x in ipairs(row) do
      if x < 0.0 then return nil end
    end
  end

  return solution
end