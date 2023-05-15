--[[

	The Slayer for Merlord's character backgrounds.
    An MWSE-lua mod for Morrowind
    
    Note: This mod requires "Merlord's character backgrounds" to work.
           https://www.nexusmods.com/morrowind/mods/46795
    
	@version      v1.0
	@author       VvardenfellStormSage
	@last-update  May 1, 2023

]]

-- get the current merBackgrounds data
local function getData()
    local data = tes3.player.data.merBackgrounds or {}
    return data
end

-- start the mod
local function onInit(e)
	local interop = require("mer.characterBackgrounds.interop")

	-- init the slayer
	local theSlayerDoOnce
    local theSlayerBackground = {
        id = "theSlayer",
        name = "The Slayer",
        description = (
                      "Into every generation, a Slayer is born: one being in all the world, " ..
                      "a chosen one. They alone will weild the strength and skill to fight " ..
                      "the vampires, daedra, and forces of darkness; to stop the spread of their " ..
                      "evil and the swell of their number. You are the Slayer. " ..
                      "Bearing both a blessing (+5 to Agility, Strength, Speed,) and a curse " ..
                      "(+10 Weakness to Magicka), you carry your blessed stake and tome of " ..
                      "knowledge into battle. "
    ),
        doOnce = function()
			mwscript.addItem({
				reference = tes3.player,
				item = "vss_buffystake",
				count = 1
			})
			mwscript.addItem({
				reference = tes3.player,
				item = "vss_buffybk1",
				count = 1
			})
			mwscript.addSpell({
				reference = tes3.player, 
				spell = "vss_buffyblood",
			})
      end
    }
    interop.addBackground(theSlayerBackground)

end

event.register("initialized", onInit)