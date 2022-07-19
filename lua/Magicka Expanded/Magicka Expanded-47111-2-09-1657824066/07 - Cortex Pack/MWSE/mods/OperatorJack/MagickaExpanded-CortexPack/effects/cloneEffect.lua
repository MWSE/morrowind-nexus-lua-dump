local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("clone", 328)
tes3.claimSpellEffectId("cloneSource", 329)

local scriptWhitelist = {
    ["nolore"] = true
}

local clonePotionId = "OJ_ME_ClonePotion"
local clonePotionName = "Clone"

local id = "A shady smuggler"
local function onCloneSourceTick(e)	
    e:triggerSummon(id)
end

local function addCloneSourceEffect()
	framework.effects.conjuration.createBasicEffect({
		-- Base information.
		id = tes3.effect.cloneSource,
		name = "Clone Source",
		description = "Source effect for the Clone magic effect.",

		-- Basic dials.
		baseCost = 0.0,

		-- Various flags.
        canCastSelf = true,
        hasNoMagnitude = true,
        nonRecastable = true,
        casterLinked = true,
        appliesOnce = true,

		-- Graphics/sounds.
		icon = "RFD\\RFD_crt_clone.dds",
        lighting = { 0, 0, 0 },

		-- Required callbacks.
		onTick = onCloneSourceTick,
	})
end

local function onCloneTick(e)
    if (e.effectInstance.target.object.script == nil or scriptWhitelist[e.effectInstance.target.object.script]) then
        id = e.effectInstance.target.object.id
        local effect = framework.functions.getEffectFromEffectOnEffectEvent(e, tes3.effect.clone)
        local magnitude = framework.functions.getCalculatedMagnitudeFromEffect(effect)
    
        if (e.effectInstance.target.object.level <= magnitude) then
            local duration = effect.duration
            local potion = framework.alchemy.createBasicPotion({
                id = clonePotionId,
                name = clonePotionName,
                effect = tes3.effect.cloneSource,
                duration = duration
            })
        
            mwscript.equip({
                reference = e.sourceInstance.caster,
                item = potion
            })
        
        else
            tes3.messageBox("%s was too powerful to be cloned!", e.effectInstance.target.baseObject.name)
        end
    else
        tes3.messageBox("%s was unable to be cloned!", e.effectInstance.target.baseObject.name)
    end

	e.effectInstance.state = tes3.spellState.retired
end

local function addCloneEffect()
	framework.effects.conjuration.createBasicEffect({
		-- Base information.
		id = tes3.effect.clone,
		name = "Clone",
		description = "Clones the target and makes them fight alongside you. The effect's magnitude is the level of actor that can be cloned.",

		-- Basic dials.
		baseCost = 35.0,

		-- Various flags.
		allowEnchanting = true,
        allowSpellmaking = true,
        canCastTarget = true,
        canCastTouch = true,
        isHarmful = true,
        appliesOnce = true,

		-- Graphics/sounds.
		icon = "RFD\\RFD_crt_clone.dds",
        lighting = { 0, 0, 0 },

		-- Required callbacks.
		onTick = onCloneTick,
	})
end

event.register("magicEffectsResolved", addCloneEffect)
event.register("magicEffectsResolved", addCloneSourceEffect)