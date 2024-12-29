tes3.claimSpellEffectId("repairWeapon", 24009)

---@param tickParams tes3magicEffectTickEventData
local function repairWeaponTick(tickParams)
    
    local target = tickParams.effectInstance.target
    -- Check to see if the target has a weapon readied.
    if (target.mobile.readiedWeapon ~= nil) then
        local weapon = target.mobile.readiedWeapon
        -- Then check if that weapon has data...
        if weapon.itemData.condition ~= nil then
            local repairAmount = tickParams.effectInstance.magnitude*tickParams.deltaTime
            -- Creates data to track condition, so it isn't restricted to an integer.
            if target.data.fakeCondition == nil then
                target.data.fakeCondition = {}
                target.data.fakeCondition = weapon.itemData.condition
            end
            target.data.fakeCondition = math.min(target.data.fakeCondition + repairAmount, weapon.object.maxCondition)
            if weapon.itemData.condition < weapon.object.maxCondition  then
                weapon.itemData.condition = math.floor(target.data.fakeCondition)
            end
        end
    end
    
    tickParams:trigger({

    })
end

event.register(tes3.event.magicEffectsResolved, function()
    tes3.addMagicEffect({
        id = tes3.effect.repairWeapon,
        name = "Repair Weapon",
        description = "Repairs your readied weapon by the magnitude for the duration.",
        school = tes3.magicSchool.alteration,

        baseCost = 5,

        allowEnchanting = false,
        allowSpellmaking = true,
        appliesOnce = true,
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

        icon = "IB\\IB_s_repair_weapon.tga",
        particleTexture = "vfx_alt_glow.tga",
        castSound = "alteration cast",
        castVFX = "VFX_AlterationCast",
        boltSound = "alteration bolt",
        boltVFX = "VFX_AlterationBolt",
        hitSound = "alteration hit",
        hitVFX = "VFX_AlterationHit",
        areaSound = "alteration area",
        areaVFX = "VFX_AlterationArea",
        lighting = { x = 0.76, y = 0.44, z = 0.88 },
        usesNegativeLighting = false,
        
        onTick = repairWeaponTick
    })
end)
