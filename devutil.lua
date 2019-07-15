
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

function const(x)
  return (function() return x end)
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
