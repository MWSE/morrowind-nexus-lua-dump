-- Check MWSE Build --
if (mwse.buildDate == nil) or (mwse.buildDate < 20191019) then
    local function warning()
        tes3.messageBox(
            "[Simple Combat Mechanics ERROR] Your MWSE is out of date!"
            .. " You will need to update to a more recent version to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end
----------------------------

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
    require("OperatorJack.SimpleCombatMechanics.mcm")
end)


require("OperatorJack.SimpleCombatMechanics.modules.disarmament")
require("OperatorJack.SimpleCombatMechanics.modules.combatScavenging")
require("OperatorJack.SimpleCombatMechanics.modules.interactiveBystanders")

local function initialized()
    print("[Simple Combat Mechanics: INFO] Simple Combat Mechanics Initialized")
end

event.register("initialized", initialized)