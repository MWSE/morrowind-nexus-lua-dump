--[[

	Raised by Argonian for Merlord's character backgrounds.
    An MWSE-lua mod for Morrowind
    
    Note: This mod requires "Merlord's character backgrounds" to work.
           https://www.nexusmods.com/morrowind/mods/46795
    
	@version      v1.0
	@author       VvardenfellStormSage
	@last-update  March 27, 2023

]]

-- get the current merBackgrounds data
local function getData()
    local data = tes3.player.data.merBackgrounds or {}
    return data
end

-- start the mod
local function onInit(e)
	local interop = require("mer.characterBackgrounds.interop")

	-- init raised by argonian
	local lizardMomDoOnce
    local lizardMomBackground = {
        id = "lizardMom",
        name = "Raised by Argonian",
        description = (
                      "As a small child, you were found wandering Black Marsh by a kindly " ..
                      "Argonian shaman, who raised you as her own. Through her tutelage, " ..
                      "you learned the ways of the shaman (+5 to Mysticism, Illusion and Alchemy). " ..
                      "Growing up in the vast swamp also taught you to navigate it's bays and " ..
                      "bayous nearly as well as a native Argonian (learn spells: Buoyancy and Water Breathing). " ..
                      "Unfortunately, your non-argonian physiology was not designed for life in the dark " ..
                      "swamp, and your constitution suffers for it (-5 to Endurance and Strength). "
    ),
        doOnce = function()
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.mysticism,
				value = 5
			})
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.illusion,
				value = 5
			})
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.alchemy,
				value = 5 
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.endurance,
				value = -5
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.strength,
				value = -5
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.personality,
				value = -5
			})
			mwscript.addSpell({
				reference = tes3.player, 
				spell = "buoyancy"
			})
			mwscript.addSpell({
				reference = tes3.player, 
				spell = "water breathing"
			})
      end
    }
    interop.addBackground(lizardMomBackground)

end

event.register("initialized", onInit)