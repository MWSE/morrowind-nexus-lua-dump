local framework = require("OperatorJack.MagickaExpanded.magickaExpanded")
if (framework == nil) then
    local function warning ()
        tes3.messageBox(
            "[DEAD DRUID ERROR] Magicka Expanded framework is not installed!"
            .. " You will need to install it to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end

-- Require the modules for bound weapon and armor effects
require("vss.Druid.effects.boundDruidWeaponEffects")
require("vss.Druid.effects.boundDruidArmorEffects")

-- Define spellIds table and tomes table
local spellIds = {
    boundGrassSwd = "vss_drd_BoundGrassSwdSpell",
    boundWoodWard = "vss_drd_BoundWoodWardSpell"
}

local tomes = {
    {
        id = "vss_druidScroll1",
        spellId = spellIds.boundGrassSwd
    }, 
    {
        id = "vss_druidScroll2",
        spellId = spellIds.boundWoodWard
    }, 
}

-- Define registerSpells function
local function registerSpells()
    -- Define the basic spells using the framework
    framework.spells.createBasicSpell({
        id = spellIds.boundGrassSwd,
        name = "Grass Sword",
        effect = tes3.effect.boundGrassSwd,
        range = tes3.effectRange.self,
        duration = 42
    })
    framework.spells.createBasicSpell({
        id = spellIds.boundWoodWard,
        name = "Ward of Wood",
        effect = tes3.effect.boundWoodWard,
        range = tes3.effectRange.self,
        duration = 42
    })

    -- Register tomes using the framework
    framework.tomes.registerTomes(tomes)
end

-- Register registerSpells function to the MagickaExpanded:Register event
event.register("MagickaExpanded:Register", registerSpells)