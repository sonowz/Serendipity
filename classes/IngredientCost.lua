-- IngredientCost class


IngredientCost = {}
IngredientCost.__index = IngredientCost


function IngredientCost:new(resources, table)
  local obj = {}
  for i, resource in ipairs(resources) do
    if table and table[resource] then
      obj[resource] = table[resource]
    else
      obj[resource] = 0.0
    end
  end
  if table and table["time"] then
    obj["time"] = table["time"]
  else
    obj["time"] = 1.0
  end
  if table and table["depth"] then
    obj["depth"] = table["depth"]
  else
    obj["depth"] = 1.0
  end
  return setmetatable(obj, IngredientCost)
end


function IngredientCost:clone()
  local obj = table.deepcopy(self)
  return setmetatable(obj, IngredientCost)
end


function IngredientCost:add(other)
  local sum = {}
  setmetatable(sum, IngredientCost)
  for k, _ in pairs(self) do
    sum[k] = self[k] + other[k]
  end
  return sum
end


-- scala multiplication (except depth)
function IngredientCost:mul(num)
  for k, v in pairs(self) do
    if k ~= "depth" then
      self[k] = num * v
    end
  end
  return self
end


function IngredientCost:tostring()
  local str = "{"
  for k, v in pairs(self) do
    str = str..k..":"..tostring(v)..", "
  end
  return str:sub(0, -3).."}"
end


function IngredientCost:keys(no_depth)
  local keys = table.keys(self)
  if no_depth then
    table.remove(keys, "depth")
  end
  return keys
end


function IngredientCost:toarray(keys)
  local arr = {}
  for i, key in ipairs(keys) do
    arr[i] = self[key]
  end
  return arr
end
