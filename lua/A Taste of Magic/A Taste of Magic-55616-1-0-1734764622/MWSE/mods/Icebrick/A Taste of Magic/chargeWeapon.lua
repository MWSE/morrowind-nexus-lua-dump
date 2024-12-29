tes3.claimSpellEffectId("chargeWeapon", 24007)

---@param tickParams tes3magicEffectTickEventData
local function chargeWeaponTick(tickParams)
    local target = tickParams.effectInstance.target
    -- Check to see if the target has a weapon readied.
    if (target.mobile.readiedWeapon ~= nil) then
        -- Then check if that weapon has data...
        if target.mobile.readiedWeapon.itemData.charge ~= nil then
            local weapon = target.mobile.readiedWeapon
            local chargePerTick = (tickParams.effectInstance.magnitude)*tickParams.deltaTime
            if weapon.itemData.charge < weapon.object.enchantment.maxCharge then
                weapon.itemData.charge = math.min(weapon.itemData.charge + chargePerTick, weapon.object.enchantment.maxCharge)
            end
        end
    end
    tickParams:trigger({

    })
end

event.register(tes3.event.magicEffectsResolved, function()
    tes3.addMagicEffect({
        id = tes3.effect.chargeWeapon,
        name = "Charge Weapon",
        description = ("Recharges your readied weapon by the magnitude for the duration."),
        school = tes3.magicSchool.mysticism,
        baseCost = 20.0,

        allowEnchanting = true,
        allowSpellmaking = true,
        appliesOnce = false,
        canCastTarget = true,
        canCastTouch = true,
        canCastSelf = true,
        hasNoDuration = false,
        hasNoMagnitude = false,
        nonRecastable = false,
        unreflectable = false,
        isHarmful = false,
        hasContinuousVFX = false,
        targetsAttributes = false,
        targetsSkills = false,

        size = 1.25,
        sizeCap = 50,
        lighting = {0.83, 0.92, 0.97},
        usesNegativeLighting = false,

        icon = "IB\\IB_s_charge_weapon.tga",
        particleTexture = "vfx_myst_flare01.tga",
        castSound = "mysticism cast",
        castVFX = "VFX_MysticismCast",
        boltSound = "mysticism bolt",
        boltVFX = "VFX_MysticismBolt",
        hitSound = "mysticism hit",
        hitVFX = "VFX_MysticismHit",
        areaSound = "mysticism area",
        areaVFX = "VFX_MysticismArea",

        onTick = chargeWeaponTick
    })
end)
