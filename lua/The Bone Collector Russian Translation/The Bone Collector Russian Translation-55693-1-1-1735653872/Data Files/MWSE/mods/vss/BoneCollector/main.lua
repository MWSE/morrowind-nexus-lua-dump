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
        name = "Собиратель костей",
        description = (
                      "В детстве вас завораживали атрибуты смерти и " ..
                      "естественные процессы, окружающие ее. Повзрослев, вы твердо решили " ..
                      "проникнуть за завесу между жизнью и смертью и овладеть запретным искусством " ..
                      "некромантии. Вы путешествовали по миру, ища знания в самых темных " ..
                      "уголках Тамриэля, не оставляя ни одной могильной плиты нетронутой и ни одной гробницы неоскверненной. " ..
                      "Ваша учеба и преданность делу окупились, и вы овладели мастерством в темной " ..
                      "школе некромантии (+5 Колдовство, Мистицизм), но другие могут почувствовать " ..
                      "тьму, обитающую внутри вас (-5 Привлекательность). " 
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