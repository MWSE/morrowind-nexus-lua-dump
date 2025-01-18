require("Icebrick.A Taste of Magic.chargeItem")
require("Icebrick.A Taste of Magic.chargeWeapon")
require("Icebrick.A Taste of Magic.drainDodge")
require("Icebrick.A Taste of Magic.extendWeapon")
require("Icebrick.A Taste of Magic.fireAura")
require("Icebrick.A Taste of Magic.haste")
require("Icebrick.A Taste of Magic.pierce")
require("Icebrick.A Taste of Magic.quicken")
require("Icebrick.A Taste of Magic.repairWeapon")
require("Icebrick.A Taste of Magic.unbreakableWeapon")
require("Icebrick.A Taste of Magic.spellDistribution")
require("Icebrick.A Taste of Magic.frostAura")
require("Icebrick.A Taste of Magic.shockAura")
require("Icebrick.A Taste of Magic.damageTypes")
require("Icebrick.A Taste of Magic.weaknessToBCP")
require("Icebrick.A Taste of Magic.resistBCP")

--- @param e attackStartEventData
local function attackStartCallback(e)
    local effectList = e.mobile.activeMagicEffectList
    for u,effect in pairs(effectList) do
        if (effect.effectId == tes3.effect.haste) then
            e.attackSpeed = e.attackSpeed + (effect.magnitude/45)
        end
    end
end
event.register(tes3.event.attackStart, attackStartCallback)

--- @param e calcHitDetectionConeEventData
local function calcHitDetectionConeCallback(e)
    -- Increase reach if extendWeapon is in the list of effects.
    local effectList = e.attackerMobile.activeMagicEffectList
    for u,effect in pairs(effectList) do
        if (effect.effectId == tes3.effect.extendWeapon) then
            e.reach = e.reach + (effect.magnitude/45)
        end
    end
end
event.register(tes3.event.calcHitDetectionCone, calcHitDetectionConeCallback)

--- @param e calcHitChanceEventData
local function hitChanceWithDrainDodge(e)
    -- Adds the drainDodge of the target to hitChance.
    if e.target ~= nil then
        local effectList = e.target.mobile.activeMagicEffectList
        for u,effect in pairs(effectList) do
            if (effect.effectId == tes3.effect.drainDodge) then
                e.hitChance = e.hitChance + effect.magnitude
            end
        end
    end
end

local function endEffects(e)
    -- Resets initialCondition when the spell ends.
    if e.effect.id == tes3.effect.unbreakableWeapon then
        e.reference.data.initialCondition = nil
    end
    if (e.effect.effectId == tes3.effect.repairWeapon) then
        if e.reference.data.fakeCondition ~= nil then
            e.reference.data.fakeCondition = nil 
        end
    end
end

--- @param e mobileDeactivatedEventData
local function mobileDeactivatedCallback(e)
    -- Resets data when the mobile is unloaded. Makes sure the effects properly end.
    -- For spells that affect weapons, also removes the effect.
    if e.reference.data ~= nil then
        if e.reference.data.initialCondition ~= nil then
            e.reference.data.initialCondition = nil
        end
        if e.reference.data.fakeCondition ~= nil then
            e.reference.data.fakeCondition = nil
        end
    end
end


--- @param e equippedEventData
local function updateUnbreakableWeapon(e)
    if e.item.objectType ~= tes3.objectType.weapon then
        return
    end
    local effectList = e.mobile.activeMagicEffectList
    -- Looks to see if any of these spells are active. Sets data if so.
    for u,effect in pairs(effectList) do
        if (effect.effectId == tes3.effect.unbreakableWeapon) and (e.itemData ~= nil) then
            e.reference.data.initialCondition = {}
            e.reference.data.initialCondition = e.itemData.condition or nil
        end
    end
end

--- @param e unequippedEventData
local function unequippedCallback(e)
    local effectList = e.mobile.activeMagicEffectList
    for u,effect in pairs(effectList) do
        if (effect.effectId == tes3.effect.repairWeapon) then
            if e.reference.data.fakeCondition ~= nil then
                e.reference.data.fakeCondition = nil 
            end
        end
    end
end
event.register(tes3.event.unequipped, unequippedCallback)

--- @param e magicReflectEventData
local function checkPierceReflect(e)
    -- There is no absorbMagic event in MWSE currently. If it is later added, I will add it to pierce.
    for _, effect in ipairs(e.sourceInstance.sourceEffects) do
        if (effect.id == tes3.effect.pierce) then
            local pierceMagnitude = math.random(effect.min, effect.max)
            local modifiedReflect = e.reflectChance - pierceMagnitude
            if modifiedReflect > 0 then
                e.reflectChance = modifiedReflect
            else
                e.reflectChance = 0
                return
            end
        end
    end
end

--- @param e spellMagickaUseEventData
local function handleQuickenSpell(e)
    local mobile = e.caster.mobile
    for _, effect in ipairs(e.instance.source.effects) do
        if (effect.id == tes3.effect.quicken) then
            -- Fake magnitude roll because I don't think magnitude exists until you actually cast the spell.
            local fakeMagnitude = math.random(effect.min, effect.max)
            local speedMult = (fakeMagnitude*0.065)+1
            if not mobile then return end
                mobile.animationController.animationData.castSpeed = speedMult
        end
    end
end

--- @param e spellCastedEventData
local function resetCastingSpeed(e)
    --resets casting speed, to cover when it was previously increased by Quicken.
    e.caster.mobile.animationController.animationData.castSpeed = 1
end

local function initialized()
    event.register(tes3.event.calcHitChance, hitChanceWithDrainDodge)
    event.register(tes3.event.magicEffectRemoved, endEffects)
    event.register(tes3.event.equipped, updateUnbreakableWeapon)
    event.register(tes3.event.magicReflect, checkPierceReflect)
    event.register(tes3.event.spellMagickaUse, handleQuickenSpell)
    event.register(tes3.event.spellCasted, resetCastingSpeed)
    event.register(tes3.event.mobileDeactivated, mobileDeactivatedCallback)
end

event.register(tes3.event.initialized, initialized)