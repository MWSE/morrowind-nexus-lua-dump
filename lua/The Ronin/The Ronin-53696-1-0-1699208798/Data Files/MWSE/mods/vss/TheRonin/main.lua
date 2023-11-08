--[[

	The Ronin for Merlord's Character Backgrounds.
    A MWSE-lua mod for Morrowind
    
    Note: This mod requires "Merlord's Character Backgrounds."
           https://www.nexusmods.com/morrowind/mods/46795

  
	@version      v1.0
	@author       VvardenfellStormSage
	@last-update  Nov x, 2023

]]

-- get the current merBackgrounds data
local function getData()
    local data = tes3.player.data.merBackgrounds or {}
    return data
end

-- start the mod
local function onInit(e)
	local interop = require("mer.characterBackgrounds.interop")

	-- init the ronin
	local theRoninDoOnce
    local theRoninBackground = {
        id = "theRonin",
        name = "The Ronin",
        description = (
                      "Orphaned and taken as a slave in a bandit raid, you learned early on to move silently " ..
                      "to avoid beatings (+5 Stealth, +5 Agility), and rarely spoke to your captors (-10 Speechcraft, " ..
                      "-5 personality). As you grew older, you were forced to take part in the gang's nefarious acts, " ..
                      "learning the way of the blade (+10 Long Blade). Eventually, you were able to slay the bandit leader " ..
                      "and claim his prize possession - a blessed sword pilfered from a forgotten temple. Since then, you " ..
                      "have wandered Tamriel, using that thrice-blessed blade to atone for the acts you were forced to commit " ..
                      "while in servitude to the bandits. " 
    ),
        doOnce = function()
			mwscript.addItem({
				reference = tes3.player,
				item = "vss_samblade",
				count = 1
			})
			mwscript.addItem({
				reference = tes3.player,
				item = "vss_CHN_ROBE4d",
				count = 1
			})
			mwscript.addItem({
				reference = tes3.player, 
				item = "vss_GetaShoes",
				count = 1
			})
			mwscript.addItem({
				reference = tes3.player, 
				item = "AB_a_WickerHelm02",
				count = 1
			})
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.stealth,
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
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.longBlade,
				value = 10 
			})
      end
    }
    interop.addBackground(theRoninBackground)

end

event.register("initialized", onInit)