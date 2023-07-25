--[[

	Bone Collector for Merlord's Character Backgrounds.
    A MWSE-lua mod for Morrowind
    
    Note: This mod requires "Merlord's Character Backgrounds," "Necrocraft," and "Necromancer Robes."
           https://www.nexusmods.com/morrowind/mods/46795
           https://www.nexusmods.com/morrowind/mods/51211
           https://www.nexusmods.com/morrowind/mods/51775
  
	@version      v1.0
	@author       VvardenfellStormSage
	@last-update  May x, 2023

]]

-- get the current merBackgrounds data
local function getData()
    local data = tes3.player.data.merBackgrounds or {}
    return data
end

-- start the mod
local function onInit(e)
	local interop = require("mer.characterBackgrounds.interop")

	-- init bone collector
	local boneCollectorDoOnce
    local boneCollectorBackground = {
        id = "boneCollector",
        name = "The Bone Collector",
        description = (
                      "As a child, you were fascinated by the trappings of death and the " ..
                      "natural processes surrounding it. As you grew older, you became determined " ..
                      "to pierce the veil between life and death and master the forbidden art " ..
                      "of necromancy. You traveled the world, seeking knowledge in the darkest " ..
                      "corners of Tamriel, leaving no gravestone unturned or tomb undesecrated. " ..
                      "Your studies and dedication paid off, and you are proficient in the dark " ..
                      "school of necromancy (+5 Conjuration, Mysticism), but others can sense the " ..
                      "darkness dwelling within you (-5 Personality). " 
    ),
        doOnce = function()
			mwscript.addItem({
				reference = tes3.player,
				item = "bk_corpsepreperation1_c",
				count = 1
			})
			mwscript.addItem({
				reference = tes3.player,
				item = "bk_corpsepreperation2_c",
				count = 1
			})
			mwscript.addItem({
				reference = tes3.player, 
				item = "bk_corpsepreperation3_c",
				count = 1
			})
			mwscript.addItem({
				reference = tes3.player, 
				item = "_RV_Necrorobe",
				count = 1
			})
			mwscript.addItem({
				reference = tes3.player, 
				item = "_RV_Necroglove_Left",
				count = 1
			})
			mwscript.addItem({
				reference = tes3.player, 
				item = "_RV_Necroglove_Right",
				count = 1
			})
			mwscript.addItem({
				reference = tes3.player, 
				item = "_RV_Necroboots",
				count = 1
			})
			mwscript.addItem({
				reference = tes3.player, 
				item = "_RV_Necromask",
				count = 1
			})
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.conjuration,
				value = 5 
			})
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.mysticism,
				value = 5 
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.personality,
				value = -5
			})
      end
    }
    interop.addBackground(boneCollectorBackground)

end

event.register("initialized", onInit)