tes3.claimSpellEffectId("chargeItem", 24012)

---@param tickParams tes3magicEffectTickEventData
local function chargeItemTestTick(tickParams)
    local target = tickParams.effectInstance.target
    -- Check to see if the target has an item readied.
    if (target.mobile.currentEnchantedItem ~= nil) then
        local item = target.mobile.currentEnchantedItem
        -- Then check if that item has data...
        if item ~= nil then
            if item.itemData ~= nil then
                if item.itemData.charge ~= nil then
                    local chargePerTick = (tickParams.effectInstance.magnitude)*tickParams.deltaTime
                    if item.itemData.charge < item.object.enchantment.maxCharge then
                        item.itemData.charge = math.min(item.itemData.charge + chargePerTick, item.object.enchantment.maxCharge)
                    end
                end
            end
        end
    end
    tickParams:trigger({

    })
end

event.register(tes3.event.magicEffectsResolved, function()
    tes3.addMagicEffect({
        id = tes3.effect.chargeItem,
        name = "Charge Item",
        description = ("Recharges your readied enchanted item by the magnitude for the duration. After casting, switch to the item you want to charge in your magic menu."),
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

        icon = "IB\\IB_s_charge_item.tga",
        particleTexture = "vfx_myst_flare01.tga",
        castSound = "mysticism cast",
        castVFX = "VFX_MysticismCast",
        boltSound = "mysticism bolt",
        boltVFX = "VFX_MysticismBolt",
        hitSound = "mysticism hit",
        hitVFX = "VFX_MysticismHit",
        areaSound = "mysticism area",
        areaVFX = "VFX_MysticismArea",

        onTick = chargeItemTestTick
    })
end)