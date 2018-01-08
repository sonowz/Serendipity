-- IngredientCost class


IngredientCost = {}
IngredientCost.__index = IngredientCost


function IngredientCost:new(materials, table)
    local obj = {}
    for i, material in ipairs(materials) do
        if table and table[material] then
            obj[material] = table[material]
        else
            obj[material] = 0.0
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
    local obj = {}
    for k, v in pairs(self) do
        obj[k] = v
    end
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
function IngredientCost:mul(k)
    for k, v in pairs(self) do
        if k ~= "depth" then
            self[k] = k * v
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
    local keyset = {}
    for k, _ in pairs(self) do
        if not (no_depth and k == "depth") then
            table.insert(keyset, k)
        end
    end
    return keyset
end


function IngredientCost:toarray(keyset)
    local arr = {}
    for i, key in ipairs(keyset) do
        arr[i] = self[key]
    end
    return arr
end
