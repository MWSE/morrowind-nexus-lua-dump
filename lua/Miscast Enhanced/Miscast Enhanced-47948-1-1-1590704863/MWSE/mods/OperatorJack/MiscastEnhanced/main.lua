-- Make sure we have an up-to-date version of MWSE.
if (mwse.buildDate == nil) or (mwse.buildDate < 20190821) then
    event.register("initialized", function()
        tes3.messageBox(
            "[Miscast Enhanced] Your MWSE is out of date!"
            .. " You will need to update to a more recent version to use this mod."
        )
    end)
    return
end

-- Check Magicka Expanded framework.
local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
if (framework == nil) then
    local function warning()
        tes3.messageBox(
            "[Miscast Enhanced: ERROR] Magicka Expanded framework is not installed!"
            .. " You will need to install it to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
    require("OperatorJack.MiscastEnhanced.mcm")
end)

local functions = require("OperatorJack.MiscastEnhanced.functions")

-- Register handlers for vanilla magic effects.
require("OperatorJack.MiscastEnhanced.schools")
require("OperatorJack.MiscastEnhanced.effects")

local function onSpellCastedFailure(e)
    local chance = math.random(0,100)
    if (chance > 15 and functions.isDebug() == false) then
        return
    end

    local spell = e.source
    local index = math.random(1, spell:getActiveEffectCount())
    local effect = spell.effects[index]

    if (effect) then
        local effectHandler = functions.getEffectHandler(effect.id)
        if (effectHandler) then 
            functions.gatedMessageBox("Your failed attempt to cast the spell triggered a miscast.")
            effectHandler({
                caster = e.caster,
                effect = effect
            })
        else
            local school = tes3.getMagicEffect(effect.id).school
            local schoolHandler = functions.getSchoolHandler(school)

            functions.gatedMessageBox("Your failed attempt to cast the spell triggered a miscast.")
            schoolHandler({
                caster = e.caster,
                effect = effect
            })
        end
    end
end
event.register("spellCastedFailure", onSpellCastedFailure)

local function onInitialized(e)
    event.trigger("Miscast:Register")
    mwse.log("[Miscast INFO] Miscast Initialized.")
end
event.register("initialized", onInitialized)