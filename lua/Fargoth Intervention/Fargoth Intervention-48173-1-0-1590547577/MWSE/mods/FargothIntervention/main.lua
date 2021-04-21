-- Make sure we have an up-to-date version of MWSE.
if (mwse.buildDate == nil) or (mwse.buildDate < 20200521) then
    event.register("initialized", function()
        tes3.messageBox(
            "[Dwemer Teleportation Box] Your MWSE is out of date!"
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
            "[Fargoth Intervention: ERROR] Magicka Expanded framework is not installed! You will need to install it to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end
----------------------------  
tes3.claimSpellEffectId("fargothIntervention", 424)

local function teleportTick(e)
    -- Trigger into the spell system.
    if (not e:trigger()) then
        return
    end
        
    local canTeleport = not tes3.worldController.flagTeleportingDisabled
    if canTeleport then    
        local reference = tes3.findClosestExteriorReferenceOfObject({
            object = "fargoth",
        })

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
        id = tes3.effect.fargothIntervention,
        name = "Fargoth Intervention",
        description = "Teleports the caster to Fargoth.",

        -- Basic dials.
        baseCost = 2.0,

        -- Various flags.
		appliesOnce = true,
		canCastSelf = true,
		hasNoDuration = true,
		hasNoMagnitude = true,
		nonRecastable = true,

        -- Graphics/sounds.
        lighting = { 0.99, 0.95, 0.67 },

        -- Required callbacks.
        onTick = teleportTick,
    })
end

event.register("magicEffectsResolved", addEffect)

local function registerSpell()
    framework.spells.createBasicSpell({
        id = "OJGA_FargothIntervention",
        name = "Fargoth Intervention",
        effect = tes3.effect.fargothIntervention,
        range = tes3.effectRange.self,
    })
end

event.register("MagickaExpanded:Register", registerSpell)



local function onInitialized()
    if (tes3.isModActive("Fargoth Intervention.esp") == true or
        tes3.isModActive("Fargoth_Intervention.esp") == true) then
        event.register("journal", function(e)
            if (e.topic.id == "G93_FargothInter" and e.index == 110) then
                mwscript.addSpell({
                    reference = tes3.player,
                    spell = "OJGA_FargothIntervention"
                })
            end
        end)
    end
end
event.register("initialized", onInitialized)