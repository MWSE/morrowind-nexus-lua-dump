
local common = require("mer.drip.common")
local interop = require("mer.drip")
local logger = common.createLogger("Thorns")

tes3.claimSpellEffectId("thorns", 8501)
interop.registerModifier{
    id = "barbs",
    prefix = " колючки",
    value = 25,
    castType = tes3.enchantmentType.constant,
    effects = {
        {
            id = tes3.effect.thorns,
            rangeType = tes3.effectRange.self,
            min = 1,
            max = 1,
        },
    },
    validObjectTypes = {
        [tes3.objectType.armor] = true,
    },
}
interop.registerModifier{
    id = "thorns",
    prefix = " шипов",
    value = 100,
    castType = tes3.enchantmentType.constant,
    effects = {
        {
            id = tes3.effect.thorns,
            rangeType = tes3.effectRange.self,
            min = 3,
            max = 3,
        },
    },
    validObjectTypes = {
        [tes3.objectType.armor] = true,
    },
}

event.register("magicEffectsResolved", function()
    logger:trace("Creating Thorns Magic Effect")
    tes3.addMagicEffect{
        id = tes3.effect.thorns,
        name = "Шипы",
        school = tes3.magicSchool.alteration,
        description = "Причиняет урон врагам, осуществляющим физические атаки.",
        icon = "drip\\thorns_s.dds",
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
    }
end)

---@param e damagedEventData
local function onDamaged(e)
    if not e.attacker then return end
    if e.damage <= 0 then return end
    if e.source == tes3.damageSource.attack then
        if tes3.isAffectedBy{reference = e.reference, effect = tes3.effect.thorns } then
            logger:debug("%s has thorns and is being attacked by %s", e.reference, e.attacker.reference)
            local magnitude = tes3.getEffectMagnitude{
                reference = e.reference,
                effect = tes3.effect.thorns,
            }
            logger:debug("Applying %s damage to %s", magnitude, e.attacker.reference)
            e.attacker:applyDamage{
                damage = magnitude,
                applyArmor= true,
            }
        end
    end
end
event.register(tes3.event.damaged, onDamaged)