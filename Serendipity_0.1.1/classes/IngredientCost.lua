-- IngredientCost class


IngredientCost = {}
IngredientCost.__index = IngredientCost


function IngredientCost:new(materials, array)
    local obj = {}
    for i, material in ipairs(materials) do
        if array then
            obj[material] = array[i]
        else
            obj[material] = 0.0
        end
    end
    if array then
        obj["time"] = array[#array-1]
        obj["depth"] = array[#array]
    else
        obj["time"] = 0.0
        obj["depth"] = 0.0
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
    local n = 1
    for k, _ in pairs(self) do
        if not (no_depth and k == "depth") then
            keyset[n] = k
            n = n + 1
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
