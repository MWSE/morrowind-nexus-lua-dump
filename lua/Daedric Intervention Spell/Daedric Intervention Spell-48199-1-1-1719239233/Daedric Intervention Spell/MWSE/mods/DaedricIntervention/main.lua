-- Make sure we have an up-to-date version of MWSE.
if (mwse.buildDate == nil) or (mwse.buildDate < 20200521) then
    event.register("initialized", function()
        tes3.messageBox("[Daedric Intervention] Your MWSE is out of date!" ..
                            " You will need to update to a more recent version to use this mod.")
    end)
    return
end

-- Check Magicka Expanded framework.
local framework = require("OperatorJack.MagickaExpanded")
if (framework == nil) then
    local function warning()
        tes3.messageBox(
            "[Daedric Intervention: ERROR] Magicka Expanded framework is not installed! You will need to install it to use this mod.")
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end
----------------------------  
tes3.claimSpellEffectId("daedricIntervention", 425)

local ids = {marker = "OJ_maker_dae_int", spell = "OJ_intervention_daedric_spell"}
local function teleportTick(e)
    -- Trigger into the spell system.
    if (not e:trigger()) then return end

    local canTeleport = not tes3.worldController.flagTeleportingDisabled
    if canTeleport then
        local reference = tes3.findClosestExteriorReferenceOfObject({object = ids.marker})

        if (reference) then
            tes3.positionCell({
                reference = tes3.player,
                position = reference.position,
                orientation = reference.orientation,
                cell = reference.cell
            })

            e.effectInstance.state = tes3.spellState.retired
            return
        end
        -- No reference
    end
    -- Cannot teleport

    tes3.messageBox("The teleportation spell fails to function.")

    e.effectInstance.state = tes3.spellState.retired
    return
end

local function addEffect()
    framework.effects.mysticism.createBasicEffect({
        -- Base information.
        id = tes3.effect.daedricIntervention,
        name = "Daedric Intervention",
        description = "Teleports the caster to the closest Daedric ruin.",

        -- Basic dials.
        baseCost = 2.0,

        -- Various flags.
        appliesOnce = true,
        canCastSelf = true,
        hasNoDuration = true,
        hasNoMagnitude = true,
        nonRecastable = true,

        -- Graphics/sounds.
        icon = "RFD\\ME_InvDae.dds",
        lighting = {0.99, 0.95, 0.67},

        -- Required callbacks.
        onTick = teleportTick
    })
end

event.register("magicEffectsResolved", addEffect)

local function registerSpell()
    framework.spells.createBasicSpell({
        id = ids.spell,
        name = "Daedric Intervention",
        effect = tes3.effect.daedricIntervention,
        rangeType = tes3.effectRange.self
    })
end

event.register("MagickaExpanded:Register", registerSpell)

local journals = {
    ["DA_Azura"] = 30,
    ["DA_Malacath"] = 70,
    ["DA_Boethiah"] = 70,
    ["DA_Mehrunes"] = 40,
    ["DA_Mephala"] = 60,
    ["DA_MolagBal"] = 30,
    ["DA_Sheogorath"] = 70
}

local function onInitialized()
    if (tes3.isModActive("Daedric Intervention.esp") == true or
        tes3.isModActive("Daedric_Intervention.esp") == true) then
        event.register("journal", function(e)
            if (journals[e.topic.id] == e.index) then
                timer.start({
                    duration = 2,
                    callback = function()
                        local spell = tes3.getObject(ids.spell)
                        if (tes3.player.object.spells:contains(spell) == false) then
                            tes3.messageBox("You are granted the Daedric Intervention spell.")
                            mwscript.addSpell({reference = tes3.player, spell = spell})
                        end
                    end
                })
            end
        end)
    end
end
event.register("initialized", onInitialized)
