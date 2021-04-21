local magickaExpanded = include("OperatorJack.MagickaExpanded.magickaExpanded")
local forbidSleepSpell = include("MMM2020TT.effects.forbidSleep")
local summonCorruptedDoubleEffect = include("MMM2020TT.effects.summonCorruptedDouble")

if (magickaExpanded == nil) then
    local function warning()
        tes3.messageBox(
            "[Tenatious T MMM 2020 ERROR] Magicka Expanded framework is not installed!"
            .. " You will need to install it to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end

local function onInitialized()
	mwse.log("[Tenatious T MMM 2020] Initialized")
end

event.register("initialized", onInitialized)