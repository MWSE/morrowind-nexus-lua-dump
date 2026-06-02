local anim = require("openmw.animation")
local types = require("openmw.types")
local self = require("openmw.self")
local util = require("openmw.util")
local ctrls = self.controls

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
			groups[k] = v			v.g = k
			if v.name then groups[v.name] = v		end
		end
	end

	walk.slowWalk = groups.walkforward_spd07
	walk.adjustWalkMask = function()	end
	walk.adjustAnims = walk.adjustWalkMask
	if not beastRace and not types.NPC.records[self.recordId].isMale then
		walk.adjustWalkMask = function(g, o)
			if o.blendMask == 1 then
				o.blendMask = 3
			end
		end
		walk.adjustAnims = function(g, o)
			if g == "idlestorm" then
				o.blendMask = util.bitAnd(o.blendMask, 8)
			elseif g:find("spellcast$") then
				local active = anim.getActiveGroup(self, 0)
				if active:match("[^_]+") == "walkforward" then
					o.blendMask = util.bitAnd(o.blendMask, 12)
				end
			end
		end
	end
	return groups
end

return M
