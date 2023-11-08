tes3.claimSpellEffectId("ggwReintegrateArmor", 1702)

---@type tes3.armorSlot[]
local slotPriorities = {
    tes3.armorSlot.shield,
    tes3.armorSlot.cuirass,
    tes3.armorSlot.leftPauldron,
    tes3.armorSlot.rightPauldron,
    tes3.armorSlot.leftBracer,
    tes3.armorSlot.rightBracer,
    tes3.armorSlot.leftGauntlet,
    tes3.armorSlot.rightGauntlet,
    tes3.armorSlot.helmet,
    tes3.armorSlot.greaves,
    tes3.armorSlot.boots,
}

event.register("magicEffectsResolved", function()
    tes3.addMagicEffect({
        id = tes3.effect.ggwReintegrateArmor,
        name = "Reintegrate Armor",
        school = tes3.magicSchool.restoration,
        description = "This effect restores the health rating of equipped armor.",
        baseMagickaCost = 6.0,
        icon = "ggw\\s\\tx_reinteg_armo.dds",
        particleTexture = "vfx_bluecloud.tga",
        castSound = "restoration cast",
        castVFX = "VFX_RestorationCast",
        boltSound = "restoration bolt",
        boltVFX = "VFX_RestorationBolt",
        hitSound = "restoration hit",
        hitVFX = "VFX_RestorationHit",
        areaSound = "restoration area",
        areaVFX = "VFX_RestorationArea",
        allowSpellmaking = true,
        allowEnchanting = false,
        appliesOnce = false,
        canCastSelf = true,
        canCastTarget = true,
        canCastTouch = true,
        casterLinked = false,
        hasContinuousVFX = false,
        hasNoDuration = false,
        hasNoMagnitude = false,
        illegalDaedra = false,
        isHarmful = false,
        nonRecastable = false,
        targetsAttributes = false,
        targetsSkills = false,
        unreflectable = false,
        usesNegativeLighting = false,

        onTick = function(e)
            e:trigger()

            local magnitude = e.effectInstance.effectiveMagnitude
            if magnitude == 0 then
                return
            end

            e.effectInstance.state = tes3.spellState.retired

            local target = e.effectInstance.target
            if target == nil then
                return
            end

            for _, slot in ipairs(slotPriorities) do
                local stack = tes3.getEquippedItem({
                    actor = tes3.player,
                    objectType = tes3.objectType.armor,
                    slot = slot,
                })
                if stack then
                    local maxCondition = stack.object.maxCondition
                    local condition = stack.itemData.condition

                    if condition < maxCondition then
                        local effect = e.sourceInstance.sourceEffects[e.effectIndex + 1]
                        magnitude = magnitude * math.max(effect.duration, 1)

                        stack.itemData.condition = math.min(condition + magnitude, maxCondition)
                        break
                    end
                end
            end
        end,
    })
end)
