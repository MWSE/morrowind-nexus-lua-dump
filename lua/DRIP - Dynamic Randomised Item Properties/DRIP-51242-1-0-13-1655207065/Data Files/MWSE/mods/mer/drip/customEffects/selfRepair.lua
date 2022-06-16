
local common = require("mer.drip.common")
local interop = require("mer.drip")
local logger = common.createLogger("SelfRepair")

tes3.claimSpellEffectId("selfRepair", 8500)
interop.registerModifier{
    suffix = "Self-Repair",
    value = 50,
    castType = tes3.enchantmentType.constant,
    effects = {
        {
            id = tes3.effect.selfRepair,
            rangeType = tes3.effectRange.self,
            min = 5,
            max = 5,
        },
    },
    validObjectTypes = {
        [tes3.objectType.armor] = true,
        [tes3.objectType.weapon] = true,
    },
}
interop.registerModifier{
    suffix = "Fast-Repair",
    castType = tes3.enchantmentType.constant,
    effects = {
        {
            id = tes3.effect.selfRepair,
            min = 10,
            max = 10,
        },
    },
    validObjectTypes = {
        [tes3.objectType.armor] = true,
        [tes3.objectType.weapon] = true,
    },
}



event.register("magicEffectsResolved", function()
    logger:trace("Creating Self Repair Magic Effect")
    tes3.addMagicEffect{
        id = tes3.effect.selfRepair,
        name = "Self Repair",
        school = tes3.magicSchool.alteration,
        description = "Slowly restores item condition.",
        icon = "drip\\selfRepair_s.dds",
		particleTexture = "vfx_alt_glow.tga",
		castSound = "alteration cast",
		castVFX = "VFX_AlterationCast",
		boltSound = "alteration bolt",
		boltVFX = "VFX_AlterationBolt",
		hitSound = "alteration hit",
		hitVFX = "VFX_AlterationHit",
		areaSound = "alteration area",
		areaVFX = "VFX_AlterationArea",
		--True
		allowEnchanting = true,
        canCastSelf = true,
        casterLinked = true,
        hasNoDuration = true,

        --Must be false for some weird reason
        unreflectable = false,
		hasNoMagnitude = false,

        --default
        hasContinuousVFX =  false,
        nonRecastable = true,
        appliesOnce = true,
        allowSpellmaking = true,
        canCastTarget = true,
        canCastTouch = true,
        illegalDaedra = false,
        isHarmful = false,
        targetsAttributes = false,
        targetsSkills = false,
        usesNegativeLighting = false,

        onTick = function(e)
            e:trigger()
            if not e.sourceInstance then return end
            local item = e.sourceInstance.item
            local itemData = e.sourceInstance.itemData
            local effect = e.effectInstance
            if not (itemData and effect) then return end
            local magnitude = effect.magnitude
            local condition = itemData.condition
            local maxCondition = item.maxCondition


            logger:trace("self-repair magnitude: %s", magnitude)
            if condition and maxCondition then
                logger:trace("Current condition: %s", condition)
                local repairAmount = maxCondition * (magnitude/100) * e.deltaTime

                itemData.data.selfRepairLeftover = itemData.data.selfRepairLeftover or 0
                repairAmount = repairAmount + itemData.data.selfRepairLeftover
                itemData.data.selfRepairLeftover = 0
                local leftOver = repairAmount - math.floor(repairAmount)
                itemData.data.selfRepairLeftover = leftOver
                repairAmount = math.floor(repairAmount)

                logger:trace("Repair amount: %s", repairAmount)
                local newCondition = condition + repairAmount
                logger:trace("New condition: %s", newCondition)
                newCondition = math.min(newCondition, maxCondition)
                itemData.condition = newCondition
            end

        end
    }
end)