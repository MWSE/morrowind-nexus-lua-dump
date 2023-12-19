--[[

	Raised By Cultists for Merlord's Character Backgrounds.
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

	-- init cultBorn
	local cultBornDoOnce
    local cultBornBackground = {
        id = "cultBorn",
        name = "Raised By Cultists",
        description = (
                      "Your formative years could be described as less than normal. Raised in a communal cult dedicated " ..
                      "to an obscure daedric lord, you learned the arts of persuasion at a young age (+10 Speechcraft) " ..
                      "to proselytize and bring in converts. As you grew older, you learned the blade was effective (+5 " ..
                      "Short Blade) to fend off persecution. Unfortunately, the indoctrination left you more susceptible " ..
                      "to the influence of others (-10 Willpower). " 
    ),
        doOnce = function()
			mwscript.addItem({
				reference = tes3.player,
				item = "vss_RBCcerem_dagger",
				count = 1
			})
			mwscript.addItem({
				reference = tes3.player,
				item = "AB_c_CommonRobeBlack",
				count = 1
			})
			mwscript.addItem({
				reference = tes3.player, 
				item = "AB_c_CommonHoodBlack",
				count = 1
			})
			mwscript.addItem({
				reference = tes3.player, 
				item = "bk_reflectionsoncultworship...",
				count = 1
			})
			mwscript.addItem({
				reference = tes3.player, 
				item = "vss_RbCring1",
				count = 1
			})
			mwscript.addSpell({
				reference = tes3.player, 
				spell = "vss_careful_whspr"
			})
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.shortBlade,
				value = 5 
			})
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.speechcraft,
				value = 10 
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.willpower,
				value = -10
			})
      end
    }
    interop.addBackground(cultBornBackground)

end

event.register("initialized", onInit)