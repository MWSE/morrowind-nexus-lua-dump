-- Make sure we have an up-to-date version of MWSE.
if (mwse.buildDate == nil) or (mwse.buildDate < 20200521) then
    event.register("initialized", function()
        tes3.messageBox("[Call Incarnate] Your MWSE is out of date!" ..
                            " You will need to update to a more recent version to use this mod.")
    end)
    return
end

-- Check Magicka Expanded framework.
local framework = require("OperatorJack.MagickaExpanded")
if (framework == nil) then
    local function warning()
        tes3.messageBox(
            "[Call Incarnate: ERROR] Magicka Expanded framework is not installed! You will need to install it to use this mod.")
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end
----------------------------  
tes3.claimSpellEffectId("callIncarnate", 426)

local incarnates = {
    [1] = "ghost_npc_peakstar",
    [2] = "ghost_npc_idrenie nerot",
    [3] = "ghost_npc_hort_ledd",
    [4] = "ghost_npc_erur-dan",
    [5] = "ghost_npc_conoon chodal",
    [6] = "ghost_npc_ane teria"
}

local currentIncarnate

local function onTick(e)
    local caster = e.sourceInstance.caster

    if (caster ~= tes3.player) then
        e.effectInstance.state = tes3.spellState.retired
        return
    end

    if (caster.cell.id == "Cavern of the Incarnate") then
        tes3.messageBox("Call Incarnate does not work in the Cavern of the Incarnate.")
        e.effectInstance.state = tes3.spellState.ending
    end

    if (e.effectInstance.state == tes3.spellState.beginning) then
        currentIncarnate = incarnates[math.random(1, #incarnates)]
    end

    e:triggerSummon(currentIncarnate)

    if (e.effectInstance.state == tes3.spellState.ending) then currentIncarnate = nil end
end

local function addEffect()
    framework.effects.conjuration.createBasicEffect({
        -- Base information.
        id = tes3.effect.callIncarnate,
        name = "Call Incarnate",
        description = "Summons one of the previous incarnate to aid the caster in battle.",

        -- Basic dials.
        baseCost = 0.0,

        -- Various flags.
        canCastSelf = true,
        hasNoMagnitude = true,
        casterLinked = true,
        appliesOnce = true,

        -- Graphics/sounds.
        -- icon = ,
        lighting = {0, 0, 0},

        -- Required callbacks.
        onTick = onTick
    })
end

event.register("magicEffectsResolved", addEffect)

local function registerSpell()
    local spell = framework.spells.createBasicSpell({
        id = "OJGA_CallIncarnate",
        name = "Call Incarnate",
        effect = tes3.effect.callIncarnate,
        rangeType = tes3.effectRange.self,
        duration = 60
    })
    spell.castType = tes3.spellType.power
end

event.register("MagickaExpanded:Register", registerSpell)

local function onInitialized()
    if (tes3.isModActive("Call Incarnate.esp") == true or tes3.isModActive("Call_Incarnate.esp") ==
        true) then
        event.register("journal", function(e)
            if (e.topic.id == "G93_CallGhost" and e.index == 100) then
                mwscript.addSpell({reference = tes3.player, spell = "OJGA_CallIncarnate"})
            end
        end)
    end
end
event.register("initialized", onInitialized)
