-- Zerkish Hotkeys Improved - zhi_util.lua
-- utility library

local Actor     = require('openmw.types').Actor
local core      = require('openmw.core')
local debug     = require('openmw.debug')
local self      = require('openmw.self')
local types     = require('openmw.types')
local ui        = require('openmw.ui')
local I         = require('openmw.interfaces')
local util      = require('openmw.util')
local async     = require('openmw.async')

--local ZHIUI             = require('scripts.ZerkishHotkeysImproved.zhi_ui')
--local ZHIMagicSelector  = require('scripts.ZerkishHotkeysImproved.zhi_ui_magic')



-- Utility Function
-- Traverses content in layouts recursively until it finds a layout with the right name,
-- may be slow for large content hierarchies
local function findLayoutByNameRecursive(content, layoutName)
    if type(content) ~= 'table' then
        return nil
    end

    local result = nil

    for i=1, #content do
        if content[i].name == layoutName then
            return content[i]
        end

        if content[i].content ~= nil then
            result = findLayoutByNameRecursive(content[i].content, layoutName)
        end

        if result ~= nil then break end
    end

    return result
end

local function packn(...)
    return {n = select('#', ...), ...}
end
  
local function unpackn(t)
    return table.unpack(t, 1, t.n)
end
  
local function mergen(...)
    local res = {n=0}
    for i = 1, select('#', ...) do
      local t = select(i, ...)
      for j = 1, t.n do
        res.n = res.n + 1
        res[res.n] = t[j]
      end
    end
    return res
  end
  
local function bind(func, ...)
    local args = packn(...)
    return function (...)
      return func(unpackn(mergen(args, packn(...))))
    end
end

local function getEquipmentSlotForArmor(armor)
    local armorType = types.Armor.records[armor.recordId].type

    if armorType == types.Armor.TYPE.Boots then
        return Actor.EQUIPMENT_SLOT.Boots
    elseif armorType == types.Armor.TYPE.Cuirass then
        return Actor.EQUIPMENT_SLOT.Cuirass
    elseif armorType == types.Armor.TYPE.Greaves then
        return Actor.EQUIPMENT_SLOT.Greaves
    elseif armorType == types.Armor.TYPE.Helmet then
        return Actor.EQUIPMENT_SLOT.Helmet
    elseif armorType == types.Armor.TYPE.LBracer then
        -- Confusing, may be wrong
        return Actor.EQUIPMENT_SLOT.LeftGauntlet
    elseif armorType == types.Armor.TYPE.LGauntlet then
        return Actor.EQUIPMENT_SLOT.LeftGauntlet
    elseif armorType == types.Armor.TYPE.LPauldron then
        return Actor.EQUIPMENT_SLOT.LeftPauldron
    elseif armorType == types.Armor.TYPE.RBracer then
        -- Confusing, may be wrong
        return Actor.EQUIPMENT_SLOT.RightGauntlet
    elseif armorType == types.Armor.TYPE.RGauntlet then
        return Actor.EQUIPMENT_SLOT.RightGauntlet
    elseif armorType == types.Armor.TYPE.RPauldron then
        return Actor.EQUIPMENT_SLOT.RightPauldron
    elseif armorType == types.Armor.TYPE.Shield then
        return Actor.EQUIPMENT_SLOT.CarriedLeft
    end

    return nil
end

local function getBestRingSlot(equipment, itemObject)
    if not equipment then return nil end
    if not itemObject then return nil end
    if not (itemObject.type == types.Clothing) then return nil end

    local record = types.Clothing.records[itemObject.recordId]
    local cType = record.type
    if cType ~= types.Clothing.TYPE.Ring then return nil end

    -- If it's already equipped, equip to the same slot
    if equipment[Actor.EQUIPMENT_SLOT.LeftRing] == itemObject then return Actor.EQUIPMENT_SLOT.LeftRing end
    if equipment[Actor.EQUIPMENT_SLOT.RightRing] == itemObject then return Actor.EQUIPMENT_SLOT.RightRing end

    return equipment[Actor.EQUIPMENT_SLOT.LeftRing] == nil and Actor.EQUIPMENT_SLOT.LeftRing or Actor.EQUIPMENT_SLOT.RightRing
end

local function getEquipmentSlotForClothing(actor, clothing)
    local clothingType = types.Clothing.records[clothing.recordId].type

    if clothingType == types.Clothing.TYPE.Amulet then
        return Actor.EQUIPMENT_SLOT.Amulet
    elseif clothingType == types.Clothing.TYPE.Belt then
        return Actor.EQUIPMENT_SLOT.Belt
    elseif clothingType == types.Clothing.TYPE.LGlove then
        return Actor.EQUIPMENT_SLOT.LeftGauntlet
    elseif clothingType == types.Clothing.TYPE.Pants then
        return Actor.EQUIPMENT_SLOT.Pants
    elseif clothingType == types.Clothing.TYPE.RGlove then
        return Actor.EQUIPMENT_SLOT.RightGauntlet
    elseif clothingType == types.Clothing.TYPE.Ring then
        local equipment = types.Actor.getEquipment(actor)
        if equipment then
            return getBestRingSlot(equipment, clothing)
        else
            return types.Actor.EQUIPMENT_SLOT.LeftRing
        end
    elseif clothingType == types.Clothing.TYPE.Robe then
        return Actor.EQUIPMENT_SLOT.Robe
    elseif clothingType == types.Clothing.TYPE.Shirt then
        return Actor.EQUIPMENT_SLOT.Shirt
    elseif clothingType == types.Clothing.TYPE.Shoes then
        return Actor.EQUIPMENT_SLOT.Boots
    elseif clothingType == types.Clothing.TYPE.Skirt then
        return Actor.EQUIPMENT_SLOT.Skirt
    end

    return nil
end

local function getEquipmentSlotForWeapon(weapon)
    local weaponType = types.Weapon.records[weapon.recordId].type

    if weaponType == types.Weapon.TYPE.Arrow or weaponType == types.Weapon.TYPE.Bolt then
        return Actor.EQUIPMENT_SLOT.Ammunition
    else
        return Actor.EQUIPMENT_SLOT.CarriedRight
    end
end

local armorRefTable = {}
armorRefTable[types.Armor.TYPE.Boots]       = "iBootsWeight"
armorRefTable[types.Armor.TYPE.Cuirass]     = 'iCuirassWeight'
armorRefTable[types.Armor.TYPE.Greaves]     = 'iGreavesWeight'
armorRefTable[types.Armor.TYPE.Helmet]      = 'iHelmWeight'
armorRefTable[types.Armor.TYPE.LBracer]     = 'iGauntletWeight'
armorRefTable[types.Armor.TYPE.LGauntlet]   = 'iGauntletWeight'
armorRefTable[types.Armor.TYPE.LPauldron]   = 'iPauldronWeight'
armorRefTable[types.Armor.TYPE.RBracer]     = 'iGauntletWeight'
armorRefTable[types.Armor.TYPE.RGauntlet]   = 'iGauntletWeight'
armorRefTable[types.Armor.TYPE.RPauldron]   = 'iPauldronWeight'
armorRefTable[types.Armor.TYPE.Shield]      = 'iShieldWeight'

local armorSoundTable = {}
armorSoundTable['None']     = { equip = 'item bodypart up', unequip = 'item bodypart down' }
armorSoundTable['Light']    = { equip = 'item armor light up', unequip = 'item armor light down' }
armorSoundTable['Medium']   = { equip = 'item armor medium up', unequip = 'item armor medium down' }
armorSoundTable['Heavy']    = { equip = 'item armor heavy up', unequip = 'item armor heavy down' }

local function getArmorClass(record)
    --local record = types.Armor.records[armor.recordId]
    local weight = record.weight
    if weight == 0.0 then return 'NONE' end
    local refStr = armorRefTable[record.type]
    if refStr == nil then return 'NONE' end

    local refWeight = core.getGMST(refStr)
    local refLightArmor = refWeight * core.getGMST('fLightMaxMod') + 5e-4
    local refMedArmor = refWeight * core.getGMST('fMedMaxMod') + 5e-4
    
    if weight <= refLightArmor then return 'Light' end
    if weight <= refMedArmor then return 'Medium' end
    return 'Heavy'
end

local function getEquipSoundsForArmor(armor)
    local armorClass = getArmorClass(types.Armor.records[armor.recordId])
    if armorClass then
        return armorSoundTable[armorClass]
    end
    return nil
end

local weaponSoundTable = {}
weaponSoundTable[types.Weapon.TYPE.Arrow]               = { equip = 'item ammo up', unequip = 'item ammo down' }
weaponSoundTable[types.Weapon.TYPE.AxeOneHand]          = { equip = 'item weapon longblade up', unequip = 'item weapon longblade down' }
weaponSoundTable[types.Weapon.TYPE.AxeTwoHand]          = weaponSoundTable[types.Weapon.TYPE.AxeOneHand]
weaponSoundTable[types.Weapon.TYPE.BluntOneHand]        = { equip = 'item weapon blunt up', unequip = 'item weapon blunt down' }
weaponSoundTable[types.Weapon.TYPE.BluntTwoClose]       = weaponSoundTable[types.Weapon.TYPE.BluntOneHand]
weaponSoundTable[types.Weapon.TYPE.BluntTwoWide]        = weaponSoundTable[types.Weapon.TYPE.BluntTwoClose]
weaponSoundTable[types.Weapon.TYPE.Bolt]                = weaponSoundTable[types.Weapon.TYPE.Arrow]
weaponSoundTable[types.Weapon.TYPE.LongBladeOneHand]    = { equip = 'item weapon longblade up', unequip = 'item weapon longblade down' }
weaponSoundTable[types.Weapon.TYPE.LongBladeTwoHand]    = weaponSoundTable[types.Weapon.TYPE.LongBladeOneHand]
weaponSoundTable[types.Weapon.TYPE.MarksmanBow]         = { equip = 'item weapon bow up', unequip = 'item weapon bow down' }
weaponSoundTable[types.Weapon.TYPE.MarksmanCrossbow]    = { equip = 'item weapon crossbow up', unequip = 'item weapon crossbow down' }
weaponSoundTable[types.Weapon.TYPE.MarksmanThrown]      = weaponSoundTable[types.Weapon.TYPE.Arrow]
weaponSoundTable[types.Weapon.TYPE.ShortBladeOneHand]   = { equip = 'item weapon shortblade up', unequip = 'item weapon shortblade down' }
weaponSoundTable[types.Weapon.TYPE.SpearTwoWide]        = { equip = 'item weapon spear up', unequip = 'item weapon spear down' }


local function getEquipSoundsforWeapon(weapon)
    local weaponType = weapon.type.records[weapon.recordId].type
    return weaponSoundTable[weaponType]
end

local function getSkillForEffect(player, effect)
    local skills = types.NPC.stats.skills
    local skill = skills[effect.school](player).modified
    return skill
end

local armorToSkill = {
    None    = 'unarmored',
    Light   = 'lightarmor',
    Medium  = 'mediumarmor',
    Heavy   = 'heavyarmor',
}

local function getSkillForArmorClass(player, ac)
    local skillId = armorToSkill[ac]
    if not skillId then return nil end

    local skill = types.NPC.stats.skills[skillId]
    if not skill then return nil end

    local value = skill(player).modified
    return value
end

local function getSkill(player, skillName)
    local skill = types.NPC.stats.skills[skillName]
    if not skill then return 0.0 end

    return skill(player).modified
end

local function getActorStat(actor, statName)
    return types.Actor.stats.attributes[statName](actor).modified
end

local function getDynamicStat(actor, name)
    local dynamic = types.Actor.stats.dynamic[name]
    if not dynamic then 
        return nil
    end

    local current = dynamic(actor).current
    local base = dynamic(actor).base
    local modifier = dynamic(actor).modifier

    return {
        modified = math.max(0.0, base + modifier),
        current = current,
    }
end

local function getFatigueTerm(actor)
    local current = getDynamicStat(actor, 'fatigue').current
    local max = getDynamicStat(actor, 'fatigue').modified

    local normalized = math.floor(max) == 0.0 and 1.0 or math.max(0.0, current / max)

    local fFatigueBase = core.getGMST('fFatigueBase')
    local fFatigueMult = core.getGMST('fFatigueMult')

    return fFatigueBase - fFatigueMult * (1.0 - normalized)
end

-- Ported (roughly) from https://github.com/OpenMW/openmw/blob/9ea1afedcc5793adec7d6143eb8f827d469ada49/apps/openmw/mwmechanics/spellutil.cpp#L42
local function calcEffectCost(effectParams, isPotion)

    local effect = core.magic.effects.records[effectParams.id]

    local hasMagnitude = effect.hasMagnitude
    local hasDuration = effect.hasDuration
    local appliedOnce = effect.isAppliedOnce

    local minMagnitude = hasMagnitude and effectParams.magnitudeMin or 1.0
    local maxMagnitude = hasMagnitude and effectParams.magnitudeMax or 1.0

    -- NOTE Only Applied when EffectCostMethod is PlayerSpell or GameSpell ? Can this be checked from Lua?
    minMagnitude = math.max(1.0, minMagnitude)
    maxMagnitude = math.max(1.0, maxMagnitude)

    local duration = hasDuration and effectParams.duration or 1.0
    if not appliedOnce then
        duration = math.max(1.0, duration)
    end

    local fEffectCostMult = core.getGMST('fEffectCostMult')
    local iAlchemyMod = core.getGMST('iAlchemyMod')

    local durationOffset = 0
    local minArea = 0
    local costMult = fEffectCostMult

    local isPlayerSpell = false

    -- EffectCostMethod comes in here again..just guessing.
    if isPotion then
        minArea = 1.0
        costMult = iAlchemyMod
    elseif isPlayerSpell then
        durationOffset = 1.0
        minArea = 1.0
    end

    local x = 0.5 * (minMagnitude + maxMagnitude)
    x = x * (0.1 * effect.baseCost)
    x = x * (durationOffset + duration)
    x = x + (0.05 * math.max(minArea, effectParams.area) * effect.baseCost)

    return x * costMult
end

local function getTotalEffectsCost(effects, isPotion)
    local cost = 0.0
    for i=1,#effects do
        local effectCost = math.max(0.0, calcEffectCost(effects[i], isPotion))
        if effects[i].range == core.magic.RANGE.Target then
            effectCost = effectCost * 1.5
        end

        cost = cost + effectCost
    end

    return cost
end

local function getSpellCost(spell)
    if not spell.autocalcFlag then
        return spell.cost
    end

    local cost = getTotalEffectsCost(spell.effects, false)
    
    -- Equivalent to round
    return math.floor(cost + 0.5)
end

local function calcSpellBaseChance(actor, spell)
    local fEffectCostMult = core.getGMST('fEffectCostMult')
    local y = 3.40282347e+38 -- shameless steal from C++ limits
    local school = nil
    local lowestSkill = nil

    if spell.type ~= core.magic.SPELL_TYPE.Spell then
        return nil
    end

    for k, effectParams in ipairs(spell.effects) do
        local effect = core.magic.effects.records[effectParams.id]

        local val = effectParams.duration
        if not effect.isAppliedOnce then
            val = math.max(1.0, val)
        end

        val = val * 0.1 * effect.baseCost
        val = val * 0.5 * (effectParams.magnitudeMin + effectParams.magnitudeMax)
        val = val + (effectParams.area * 0.05 * effect.baseCost)
        if effect.range == core.magic.RANGE.Target then
            val = val * 1.5
        end

        val = val * fEffectCostMult
        local s = 2.0 * getSkillForEffect(actor, effect)
        if s - val < y then
            y = s - val
            school = effect.school
            lowestSkill = s
        end
    end

    if (school) then
        local first = string.sub(school, 1, 1)
        school = string.upper(first) .. string.sub(school, 2, #school)
    end

    local willpower = getActorStat(actor, 'willpower')
    local luck = getActorStat(actor, 'luck')

    local castChance = (lowestSkill - getSpellCost(spell) + 0.2 * willpower + 0.1 * luck)

    return school, castChance
end

-- It's unreal to think this function isn't just exposed through the API.
-- This is essentially translated from the C++ code on OpenMW's Github.
local function getSpellSchoolAndCastChance(actor, spell, checkMagicka)

    local school, baseChance = calcSpellBaseChance(actor, spell)
    baseChance = baseChance

    -- Check for silenced
    local activeEffects = types.Actor.activeEffects(actor)
    local silenceEffect = activeEffects:getEffect(core.magic.EFFECT_TYPE.Silence)
    if silenceEffect and silenceEffect.magnitude > 0 then
        return school, 0.0
    end

    local actorSpells = types.Actor.spells(actor)
    if actorSpells and spell.type == core.magic.SPELL_TYPE.Power then
        return school, (actorSpells:canUsePower(spell) and 100.0 or 0.0)
    end

    if debug.isGodMode() then return school, 100.0 end

    if spell.type ~= core.magic.SPELL_TYPE.Spell then return school, 100.0 end

    -- nil considered to be true
    if checkMagicka ~= false then
        local spellCost = getSpellCost(spell)
        local mStat = getDynamicStat(actor, 'magicka')
        if (mStat and mStat.current) and (mStat.current < spellCost) then return school, 0.0 end
    end

    if spell.alwaysSucceedFlag then return school, 100.0 end

    local castBonus = 0.0
    local soundEffect = activeEffects:getEffect(core.magic.EFFECT_TYPE.Sound)
    castBonus = -(soundEffect and soundEffect.magnitude or 0.0)
    local castChance = baseChance + castBonus
    castChance = castChance * getFatigueTerm(actor)

    -- Always cap for our purposes
    castChance = math.min(100.0, math.max(0.0, castChance))

    return school, castChance
end

local function getWeaponSubtext(weaponRecord)
    if weaponRecord == nil then return nil end

    if weaponRecord.type == types.Weapon.TYPE.AxeOneHand then return "Axe, One Handed" end
    if weaponRecord.type == types.Weapon.TYPE.AxeTwoHand then return "Axe, Two Handed" end
    if weaponRecord.type == types.Weapon.TYPE.BluntOneHand then return "Blunt, One Handed" end
    if weaponRecord.type == types.Weapon.TYPE.BluntTwoClose then return "Blunt, Two Handed" end
    if weaponRecord.type == types.Weapon.TYPE.BluntTwoWide then return "Blunt, Two Handed" end
    if weaponRecord.type == types.Weapon.TYPE.LongBladeOneHand then return "Long Blade, One Handed" end
    if weaponRecord.type == types.Weapon.TYPE.LongBladeTwoHand then return "Long Blade, Two Handed" end
    if weaponRecord.type == types.Weapon.TYPE.MarksmanBow then return "Marksman" end
    if weaponRecord.type == types.Weapon.TYPE.MarksmanCrossbow then return "Marksman" end
    if weaponRecord.type == types.Weapon.TYPE.MarksmanThrown then return "Marksman" end
    if weaponRecord.type == types.Weapon.TYPE.ShortBladeOneHand then return "Short Blade, One Handed" end
    if weaponRecord.type == types.Weapon.TYPE.SpearTwoWide then return "Spear, Two Handed" end

    return nil
end


local textureCache = {}

local function getCachedTexture(props)
    local key = ""
    for k, v in pairs(props) do
        key = key .. tostring(v)
    end

    if textureCache[key] then
        return textureCache[key]
    end

    local texture = ui.texture(props)
    textureCache[key] = texture
    return texture
end


return {

    bindFunction = bind,

    equalAnyOf = function(thing, ...) 
        local args = { ... }
        for i, v in pairs(args) do
            if (thing == v) then return true end
        end
        return false
    end,

    getHotkeyIdentifier = function(hotbar, num)
        return string.format('ZHI_Hotbar_%d_%d', hotbar, num % 10)
    end,

    findLayoutByNameRecursive = findLayoutByNameRecursive,

    getEquipmentSlotForItem = function(actor, item)
        print('getEquipmentSlotForItem', item, item.type)
        if item.type == types.Armor then
            print('getEquipmentSlotForItem - armor')
            return getEquipmentSlotForArmor(item)
        elseif item.type == types.Clothing then
            print('getEquipmentSlotForItem - clothing')
            return getEquipmentSlotForClothing(actor, item)
        elseif item.type == types.Weapon then
            print('getEquipmentSlotForItem - weapon')
            return getEquipmentSlotForWeapon(item)
        elseif item.type == types.Light then
            print('getEquipmentSlotForItem - light')
            return Actor.EQUIPMENT_SLOT.CarriedLeft
        elseif item.type == types.Lockpick then
            print('getEquipmentSlotForItem - lockpick')
            return Actor.EQUIPMENT_SLOT.CarriedRight
        elseif item.type == types.Probe then
            print('getEquipmentSlotForItem - probe')
            return Actor.EQUIPMENT_SLOT.CarriedRight
        end
    end,

    getSoundsForItem = function(item)
        if item.type == types.Apparatus then
            return { equip = 'item apparatus up', unequip = 'item apparatus down' }
        -- elseif item.type == types.Ammunition then
        --     return { equip = 'item ammo up', unequip = 'item ammo down' }
        elseif item.type == types.Armor then
            return getEquipSoundsForArmor(item)
        elseif item.type == types.Book then

        elseif item.type == types.Clothing then
            local record = types.Clothing.records[item.recordId]
            if record.type == types.Clothing.TYPE.Ring then
                return { equip = 'item ring up', unequip = 'item ring down' }
            else
                return { equip = 'item clothes up', unequip = 'item clothes down' }
            end
        elseif item.type == types.Ingredient then
            return { equip = 'item ingredient up', unequip = 'item ingredient down' }
        elseif item.type == types.Lockpick then
            return { equip = 'item lockpick up', unequip = 'item lockpick down'}
        elseif item.type == types.Potion then
            return { equip = 'item potion up', unequip = 'item potion down' }
        elseif item.type == types.Probe then
            return { equip = 'item probe up', unequip = 'item probe down' }
        elseif item.type == types.Repair then
            return { equip = 'item repair up', unequip = 'item repair down' }
        elseif item.type == types.Weapon then
            return getEquipSoundsforWeapon(item)
        end
    end,

    getSpellSchoolAndCastChance = getSpellSchoolAndCastChance,

    getSpellSchool = function(spell)
        local school, _ = getSpellSchoolAndCastChance(self, spell)
        return school
    end,

    getSpellCastChance = function(spell)
        local _, chance = getSpellSchoolAndCastChance(self, spell)
        return chance
    end,

    getSpellCost = getSpellCost,

    getWeaponTypeString = function(weaponRecord)
        if weaponRecord == nil then return nil end

        if weaponRecord.type == types.Weapon.TYPE.AxeOneHand then return "Axe, One Handed" end
        if weaponRecord.type == types.Weapon.TYPE.AxeTwoHand then return "Axe, Two Handed" end
        if weaponRecord.type == types.Weapon.TYPE.BluntOneHand then return "Blunt, One Handed" end
        if weaponRecord.type == types.Weapon.TYPE.BluntTwoClose then return "Blunt, Two Handed" end
        if weaponRecord.type == types.Weapon.TYPE.BluntTwoWide then return "Blunt, Two Handed" end
        if weaponRecord.type == types.Weapon.TYPE.LongBladeOneHand then return "Long Blade, One Handed" end
        if weaponRecord.type == types.Weapon.TYPE.LongBladeTwoHand then return "Long Blade, Two Handed" end
        if weaponRecord.type == types.Weapon.TYPE.MarksmanBow then return "Marksman" end
        if weaponRecord.type == types.Weapon.TYPE.MarksmanCrossbow then return "Marksman" end
        if weaponRecord.type == types.Weapon.TYPE.MarksmanThrown then return "Marksman" end
        if weaponRecord.type == types.Weapon.TYPE.ShortBladeOneHand then return "Short Blade, One Handed" end
        if weaponRecord.type == types.Weapon.TYPE.SpearTwoWide then return "Spear, Two Handed" end

        return nil
    end,

    getItemSubText = function(record, type)
        if type == types.Apparatus then
            return 'Apparatus'
            -- if record.type == types.Apparatus.TYPE.Alembic then return 'Alembic'
            -- elseif record.type == types.Apparatus.TYPE.Calcinator then return 'Calcinator'
            -- elseif record.type == types.Apparatus.TYPE.Alembic then return 'Mortar and Pestle'
            -- elseif record.type == types.Apparatus.TYPE.Retort then return 'Retort'
            -- else return nil end
        elseif type == types.Armor then
            local slotStr = nil
            if record.type == types.Armor.TYPE.Boots then slotStr = "Boots"
            elseif record.type == types.Armor.TYPE.Cuirass then slotStr = "Cuirass"
            elseif record.type == types.Armor.TYPE.Greaves then slotStr = "Greaves"
            elseif record.type == types.Armor.TYPE.Helmet then slotStr = "Helmet"
            elseif record.type == types.Armor.TYPE.LBracer then slotStr = "Left Bracer"
            elseif record.type == types.Armor.TYPE.LGauntlet then slotStr = "Left Gauntlet"
            elseif record.type == types.Armor.TYPE.LPauldron then slotStr = "Left Pauldron"
            elseif record.type == types.Armor.TYPE.RBracer then slotStr = "Right Bracer"
            elseif record.type == types.Armor.TYPE.RGauntlet then slotStr = "Right Gauntlet"
            elseif record.type == types.Armor.TYPE.RPauldron then slotStr = "Right Pauldron"
            elseif record.type == types.Armor.TYPE.Shield then slotStr = "Shield"
            end
            return string.format("%s, %s Armor", slotStr, getArmorClass(record))
        elseif type == types.Book then
            return record.isScroll and "Scroll" or "Book"
        elseif type == types.Clothing then
            local slotStr = nil
            if record.type == types.Clothing.TYPE.Amulet then slotStr = "Amulet"
            elseif record.type == types.Clothing.TYPE.Belt then slotStr = "Belt"
            elseif record.type == types.Clothing.TYPE.LGlove then slotStr = "Left Glove"
            elseif record.type == types.Clothing.TYPE.Pants then slotStr = "Pants"
            elseif record.type == types.Clothing.TYPE.RGlove then slotStr = "Right Glove"
            elseif record.type == types.Clothing.TYPE.Ring then slotStr = "Ring"
            elseif record.type == types.Clothing.TYPE.Robe then slotStr = "Robe"
            elseif record.type == types.Clothing.TYPE.Shirt then slotStr = "Shirt"
            elseif record.type == types.Clothing.TYPE.Shoes then slotStr = "Shoes"
            elseif record.type == types.Clothing.TYPE.Skirt then slotStr = "Skirt"
            end
            return string.format("%s, Clothing", slotStr)
        elseif type == types.Ingredient then
            return "Ingredient"
        elseif type == types.Light then
            return "Light"
        elseif type == types.Lockpick then
            return "Lockpick"
        elseif type == types.Potion then
            return "Potion"
        elseif type == types.Probe then
            return "Probe"
        elseif type == types.Repair then
            return "Repair Tool"
        elseif type == types.Weapon then
            return getWeaponSubtext(record)
        elseif type == types.Miscellaneous then
            return "Miscellaneous"
        end
    end,

    getArmorClass = getArmorClass,

    getArmorRatingForPlayer = function(armorRecord)
        local class = getArmorClass(armorRecord)
        local skill = getSkillForArmorClass(self, class)
        return math.floor(armorRecord.baseArmor * (skill / 30.0))
    end,

    getEnchantTypeText = function(enchantment)
        if enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnStrike then 
            return "Cast on Strike"
        elseif enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnUse then 
            return "Cast on Use"
        elseif enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnce then 
            return "Cast Once"
        elseif enchantment.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then 
            return "Constant Effect"
        end
        return nil
    end,

    getSkillForPlayer = function(name)
        return getSkill(self, name)
    end,

    getCachedTexture = getCachedTexture,

    getSpellEffectBigIconPath = function(fullPath)
        local pattern = "[%w_]+.dds"
        
        local b, e = string.find(fullPath, pattern)
        local fileLocation = string.sub(fullPath, 1, b - 1)
        local filename = string.sub(fullPath, b, e)

        return string.format("%sb_%s", fileLocation, filename)
    end,

    capitalize = function(text)
        if type(text) ~= 'string' then return nil end
        if #text == 0 then return text end
        local first = string.sub(text, 1, 1)
        return string.upper(first) .. string.sub(text, 2, #text)
    end,

    formatNumber = function(numStr)
        local b, e = string.find(numStr, "[0-9]*.[0]*[1-9]+")
        local s = numStr
        if b ~= nil and e ~= nil then
            s = string.sub(numStr, 1, b - 1) .. string.sub(numStr, b, e)
        end
        return s
    end,
}
