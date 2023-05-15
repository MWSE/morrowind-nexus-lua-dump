--[[
  Simple Level mod
  by rfuzzo
  version 1.0

	Simply caries over unused attribute levelups. If you pick an attribute when leveling up, all levelups for that attributes are lost. 

	E.g. 
	- Before leveling up you have Strength: 10 level ups, Int 2 level ups. 
	- At level up you pick Strength, Endur
]] --
local llu_cache = {}
local attr_cache = {}

--- @param e preLevelUpEventData
local function preLevelUpCallback(e)
	-- mwse.log("----------------- preLevelUpCallback -----------------")

	-- cache pre levelup values
	local mp = tes3.mobilePlayer

	-- mwse.log("levelupsPerAttribute")
	for i, v in ipairs(mp.levelupsPerAttribute) do
		-- mwse.log(i .. ": " .. v)
		llu_cache[i] = v
	end
	-- mwse.log("attributes")
	for i, v in ipairs(mp.attributes) do
		-- mwse.log(i .. ": " .. v.base)
		attr_cache[i] = v.base
	end

end
event.register(tes3.event.preLevelUp, preLevelUpCallback)

--- @param e levelUpEventData
local function levelUpCallback(e)
	-- mwse.log("----------------- levelUpCallback -----------------")

	local mp = tes3.mobilePlayer
	for i, v in ipairs(mp.attributes) do
		-- mwse.log(i .. ": " .. v.base)
		local diff = v.base - attr_cache[i]
		-- mwse.log("diff: " .. diff)
		if diff == 0 then
			-- retrieve the cached value
			local cached = llu_cache[i]
			if cached > 0 then
				-- mwse.log("cached for " .. i .. ": " .. cached)
				-- add to player
				mp.levelupsPerAttribute[i] = cached
			end
		end
	end

	-- cleanup
	llu_cache = {}
	attr_cache = {}
end
event.register(tes3.event.levelUp, levelUpCallback)
