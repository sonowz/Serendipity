function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
    return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
    tostring( v )
  end
end

function table.key_to_str ( k )
if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
  return k
else
  return "[" .. table.val_to_str( k ) .. "]"
end
end

function table.tostring( tbl )
local result, done = {}, {}
for k, v in ipairs( tbl ) do
  table.insert( result, table.val_to_str( v ) )
  done[ k ] = true
end
for k, v in pairs( tbl ) do
  if not done[ k ] then
  table.insert( result,
    table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
  end
end
return "{" .. table.concat( result, "," ) .. "}"
end

function table.contains(tbl, x)
  for _, value in pairs(table) do
    if value == x then
      return true
    end
  end
  return false
end

function table.unique(tbl)
  local hash = {}
  local res = {}

  for _,v in ipairs(tbl) do
    if (not hash[v]) then
      res[#res+1] = v
      hash[v] = true
    end
  end
  return res
end

-- From https://github.com/Afforess/Factorio-Stdlib/blob/536e9a7799aaa5cc07242c64a6b4c0cc076f7af8/stdlib/utils/table.lua
--- For all string or number values in an array map them to a key = true table
-- @usage local a = {"v1", "v2"}
-- table.array_to_dict_bool(a) -- return {["v1"] = true, ["v2"]= true}
-- @tparam table tbl the table to convert
-- @treturn table the converted table
function table.arr_to_bool(tbl)
  local newtbl = {}
  for _, v in pairs(tbl) do
    if type(v) == "string" or type(v) == "number" then
      newtbl[v] = true
    end
  end
  return newtbl
end

-- {{k, v}, {k, v}} -> {k: {v1, v2}, k: {v1, v2}}
function table.from_assoc(tbl)
  local newtbl = {}
  for _, x in ipairs(tbl) do
    local k, v = x[0], x[1]
    if not newtbl[k] then newtbl[k] = {} end
    table.insert(newtbl[k], v)
  end
  return newtbl
end

--http://snippets.luacode.org/snippets/Deep_Comparison_of_Two_Values_3
function table.deepcompare(t1,t2,ignore_mt)
  local ty1 = type(t1)
  local ty2 = type(t2)
  if ty1 ~= ty2 then return false end
  -- non-table types can be directly compared
  if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
  -- as well as tables which have the metamethod __eq
  local mt = getmetatable(t1)
  if not ignore_mt and mt and mt.__eq then return t1 == t2 end
  for k1,v1 in pairs(t1) do
  local v2 = t2[k1]
  if v2 == nil or not table.deepcompare(v1,v2) then return false end
  end
  for k2,v2 in pairs(t2) do
  local v1 = t1[k2]
  if v1 == nil or not table.deepcompare(v1,v2) then return false end
  end
  return true
end

-- Pseudorandom number generator
-- https://stackoverflow.com/questions/20154991/generating-uniform-random-numbers-in-lua
local A1, A2 = 727595, 798405  -- 5^17=D20*A1+A2
local D20, D40 = 1048576, 1099511627776  -- 2^20, 2^40
local X1, X2 = 0, 1
function randseed(seed) X2 = seed end
function rand()
  local U = X2*A2
  local V = (X1*A2 + X2*A1) % D20
  V = (V*D20 + U) % D40
  X1 = math.floor(V/D20)
  X2 = V - X1*D20
  return V/D40
end


local logFormat = {comment = false, numformat = '%1.8g' }
function flog(obj)
  log( serpent.block( obj, logFormat ) )
end
