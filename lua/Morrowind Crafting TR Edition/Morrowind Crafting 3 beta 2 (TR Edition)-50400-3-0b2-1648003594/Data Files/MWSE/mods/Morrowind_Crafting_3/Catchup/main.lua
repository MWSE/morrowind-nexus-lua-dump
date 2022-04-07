--[[ Playing catch-up with skill levels, from legacy Morrowind scripting to Lua ]]--

local mc = require("Morrowind_Crafting_3.mc_common")
local skillModule = require("OtherSkills.skillModule")

local thing, DoItToIt, levelMatch, currentKit

local function levelMatch(skillID)
	local oldLevel, Catchup
	--if skillID == "mc_Masonry" then
	--	oldLevel = tes3.findGlobal(string.lower("mc_crafting")).value
	--else
		oldLevel = tes3.findGlobal(string.lower(skillID)).value
	--end
	Catchup = oldLevel - skillModule.getSkill(skillID).value
	--if skillModule.getSkill(skillID).value < oldLevel then
		skillModule.incrementSkill( skillID, {value = Catchup} )
	--end

--- tes3.getSkill(tes3.skill.alchemy)
end

local function DoItToIt()
	local ttemp
	local skillID

	ttemp = levelMatch("mc_Smithing")
	ttemp = levelMatch("mc_Fletching")
	ttemp = levelMatch("mc_Sewing")
	ttemp = levelMatch("mc_Crafting")
	ttemp = levelMatch("mc_Masonry")
	ttemp = levelMatch("mc_Woodworking")
	ttemp = levelMatch("mc_Cooking")
	ttemp = levelMatch("mc_Mining")
end

local function onActivate(e)
	if (e.activator == tes3.player) then
		if e.target.object.id == "mc_catchup" then
			if not tes3.menuMode() then
				currentKit = e.target
			end
			DoItToIt()
		end
    end
end

event.register("activate", onActivate)
