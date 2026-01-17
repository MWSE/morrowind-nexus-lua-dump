local anim = require("openmw.animation")
local types = require("openmw.types")
local self = require("openmw.self")

local animGroups = require("scripts.DynamicAnimations.animations.config")
local M = {}

function M.initGroups(walk)
	local groups = {}
	local baseAnims = { "xbase_anim" }
	local beastRace = types.NPC.records[self.recordId].race
	beastRace = types.NPC.races.records[beastRace].isBeast and beastRace or nil
	if beastRace then
		baseAnims = { "xbase_animkna" }
		if beastRace == "argonian" then
			table.insert(baseAnims, "xargonian_swimkna")
		end
	elseif not types.NPC.records[self.recordId].isMale then
		table.insert(baseAnims, "xbase_anim_female")
	end
	for _, kf in ipairs(baseAnims) do
		for k, v in pairs(animGroups[kf]) do
			groups[k] = v			v.id = k
			if v.name then groups[v.name] = v		end
		end
	end
	walk.slowWalk = groups.walkforward_spd07
	walk.adjustWalkMask = function()	end
	walk.adjustAnims = walk.adjustWalkMask
	if beastRace then
		walk.adjustAnims = function(g, o)
			if g == "idle" then
				o.speed = 0.5
			end
		end
	elseif not types.NPC.records[self.recordId].isMale then
		walk.adjustWalkMask = function(g, o)
			if o.blendMask == 1 then
				o.blendMask = 3
			end
		end
		walk.adjustAnims = function(g, o)
			if g == "idlestorm" then
				if o.blendMask == 10 then	o.blendMask = 8		end
			elseif g:find("spellcast$") or g == "weapontwohand" then
				local active = anim.getActiveGroup(self, 0)
				if active == walk.f or active:find(walk.f_) then
					o.blendMask = 12
				end
			end
		end
	end
	return groups
end

return M
