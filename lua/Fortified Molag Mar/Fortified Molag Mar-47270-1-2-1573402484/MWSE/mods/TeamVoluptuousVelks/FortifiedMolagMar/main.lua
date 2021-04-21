-- Check MWSE Build --
if (mwse.buildDate == nil) or (mwse.buildDate < 20191019) then
    local function warning()
        tes3.messageBox(
            "[Fortified Molag Mar ERROR] Your MWSE is out of date!"
            .. " You will need to update to a more recent version to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end
----------------------------

-- Check Magicka Expanded framework --
local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
if (framework == nil) then
    local function warning()
        tes3.messageBox(
            "[Fortified Molag Mar  ERROR] Magicka Expanded framework is not installed!"
            .. " You will need to install it to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end
----------------------------

-- Load Configuration --
-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
    dofile("Data Files\\MWSE\\mods\\TeamVoluptuousVelks\\FortifiedMolagMar\\mcm.lua")
end)
----------------------------

-- Pre-Init Requires --
require("TeamVoluptuousVelks.FortifiedMolagMar.events.magicEffectsResolved")
require("TeamVoluptuousVelks.FortifiedMolagMar.events.registerSpells")
----------------------------

-- Initilization Section --
local function onInitialized()
    if not tes3.isModActive("Fortified Molag Mar.ESP") then
        print("[Fortified Molag Mar: INFO] ESP not loaded")
        return
    end

    math.randomseed(os.time())
    math.random()
    math.random()
    math.random()

    require("TeamVoluptuousVelks.FortifiedMolagMar.mechanics.artifact")
    require("TeamVoluptuousVelks.FortifiedMolagMar.mechanics.amulet")

    require("TeamVoluptuousVelks.FortifiedMolagMar.quests.aFriendLost")
    require("TeamVoluptuousVelks.FortifiedMolagMar.quests.aFriendMourned")
    require("TeamVoluptuousVelks.FortifiedMolagMar.quests.aFriendReturned")
    require("TeamVoluptuousVelks.FortifiedMolagMar.quests.aFriendAvenged")
    require("TeamVoluptuousVelks.FortifiedMolagMar.quests.aFriendReborn")

	print("[Fortified Molag Mar: INFO] Initialized Fortified Molag Mar")
end
event.register("initialized", onInitialized)
----------------------------

-- Loaded Section --
local function onLoaded()
    local common = require("TeamVoluptuousVelks.FortifiedMolagMar.common")
    tes3.player.data.fortifiedMolarMar = tes3.player.data.fortifiedMolarMar or common.data.playerData

	print("[Fortified Molag Mar: INFO] Loaded Fortified Molag Mar")
end
event.register("loaded", onLoaded)
----------------------------