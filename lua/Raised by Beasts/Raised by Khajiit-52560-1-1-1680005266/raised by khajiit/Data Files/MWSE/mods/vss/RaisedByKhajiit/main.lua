--[[

	Raised by Khajiit for Merlord's character backgrounds.
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

	-- init raised by khajiit
	local catDadDoOnce
    local catDadBackground = {
        id = "catDad",
        name = "Raised by Khajiit",
        description = (
                      "As a foundling raised by a mad khajiit hermit, you have learned to" ..
                      "defend yourself with only your fists (+10 Hand to Hand) and " ..
                      "to move with purpose and grace (+5 to Acrobatics, Sneak, Agility). " ..
                      "Unfortunately, your isolated upbringing has had a detrimental effect on your personality, " ..
                      "and left you less well-spoken (-10 to Speechcraft, -5 to Personality). "
    ),
        doOnce = function()
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.handToHand,
				value = 10
			})
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.acrobatics,
				value = 5
			})
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.sneak,
				value = 5 
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.agility,
				value = 5
			})
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.speechcraft,
				value = -10
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.personality,
				value = -5
			})
      end
    }
    interop.addBackground(catDadBackground)

end

event.register("initialized", onInit)