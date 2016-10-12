 -- RNG for Factorio mods.
 
 -- Based on: 
 -- MT19937: 32-bit Mersenne Twister by Matsumoto and Nishimura, 1998
 -- http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/ARTICLES/mt.pdf
 -- https://en.wikipedia.org/wiki/Mersenne_Twister

 -- This work is licensed under the Creative Commons Attribution 4.0 International License. 
 -- To view a copy of this license, visit http://creativecommons.org/licenses/by/4.0/.
 
 -- Author: Mr Doomah
 -- Contact: https://forums.factorio.com/memberlist.php?mode=viewprofile&u=7604
 
local w, n, m, r = 32, 624, 397, 31
local a = 0x9908B0DF
local u = 11
local s, b = 7, 0x9D2C5680
local t, c = 15, 0xEFC60000
local l = 18
local f = 1812433253


 -- Assign functions
local bnot = bit32.bnot
local bxor = bit32.bxor
local band = bit32.band
local bor = bit32.bor
local rshift = bit32.rshift
local lshift = bit32.lshift

local function int32(int) -- 32 bits
	return band(int, 0xFFFFFFFF)
end

local lower_mask = lshift(1, r) -1
local upper_mask = int32(bnot(lower_mask))
 
twister = {}

 -- Initialize the generator from a seed
function twister:seed_mt(seed)
	self.index = n
	if not seed then seed = game.surfaces["nauvis"].map_gen_settings.seed end
	self.MT[0] = int32(seed)
	for i = 1, n-1 do
		self.MT[i] = int32(f * bxor(self.MT[i-1], rshift(self.MT[i-1], w-2) + i))
	end
end

 -- Extract a tempered value based on self.MT[self.index]
 -- calling twist() every n numbers
function twister:extract_number()
	if self.index >= n then
		if self.index > n then 
			self:seed_mt()
		end
		self:twist()
	end
	
	local y = self.MT[self.index]
	y = bxor(y, rshift(y, u))
	y = bxor(y, band(lshift(y, s), b))
	y = bxor(y, band(lshift(y, t), c))
	y = bxor(y, rshift(y, l))
	
	self.index = self.index+1
	return int32(y)
end 


 -- Generate the next n values from the series x_i 
function twister:twist()
	for i = 0, n-1 do
		local x = bor(band(self.MT[i], upper_mask), band(self.MT[(i+1) % n], lower_mask))
		local xA = rshift(x, 1)
		if x % 2 ~= 0 then
			xA = bxor(xA, a)
		end
		self.MT[i] = int32(bxor(self.MT[(i + m) % n], xA))
	end
	self.index = 0
end


 -- Function to call to get a random number
function twister:rng(p, q)
	if p then
		if q then
			return p + self:extract_number() % (q - p + 1)
		else
			return 1 + self:extract_number() % p
		end
	else
		return self:extract_number() / 0xFFFFFFFF
	end
end


 -- Get a handler
function get_handler(seed)
	global.handlers = global.handlers or {}
	local handle_number = #global.handlers +1
	global.handlers[handle_number] = twister
	global.handlers[handle_number].MT = {}
	global.handlers[handle_number].index = n+1
	global.handlers[handle_number]:seed_mt(seed)
	return handle_number	
end

remote.add_interface("MT",{
	get_handler = get_handler, 
	random = function(handle_number, p, q)
		return global.handlers[handle_number]:rng(p, q)
	end,
	randomseed = function(handle_number, seed)
		return global.handlers[handle_number]:seed_mt(seed)
	end
	})