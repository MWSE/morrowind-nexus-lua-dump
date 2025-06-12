
local Actor = require('openmw.types').Actor
local core = require('openmw.core')
local types = require('openmw.types')


local ZStats = require('scripts.ZModUtils.Utility.Stats')

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

-- Table of reference weight names
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

-- Table of sounds used to equip armor.
local armorSoundTable = {}
armorSoundTable['None']     = { equip = 'item bodypart up', unequip = 'item bodypart down' }
armorSoundTable['Light']    = { equip = 'item armor light up', unequip = 'item armor light down' }
armorSoundTable['Medium']   = { equip = 'item armor medium up', unequip = 'item armor medium down' }
armorSoundTable['Heavy']    = { equip = 'item armor heavy up', unequip = 'item armor heavy down' }

local armorToSkill = {
    None    = 'unarmored',
    Light   = 'lightarmor',
    Medium  = 'mediumarmor',
    Heavy   = 'heavyarmor',
}

local function getArmorClass(armorRecord)
    if (not armorRecord) or (not armorRecord.weight) then return 'NONE' end

    --local record = types.Armor.records[armor.recordId]
    local weight = armorRecord.weight
    if weight == 0.0 then return 'NONE' end
    local refStr = armorRefTable[armorRecord.type]
    if refStr == nil then return 'NONE' end

    local refWeight = core.getGMST(refStr)
    local refLightArmor = refWeight * core.getGMST('fLightMaxMod') + 5e-4
    local refMedArmor = refWeight * core.getGMST('fMedMaxMod') + 5e-4
    
    if weight <= refLightArmor then return 'Light' end
    if weight <= refMedArmor then return 'Medium' end
    return 'Heavy'
end

local function getSkillForArmorClass(player, ac)
    if not player then return nil end
    if not ac then return nil end

    local skillId = armorToSkill[ac]
    if not skillId then return nil end

    return ZStats.getActorSkill(player, skillId)
end

local function getEquipSoundsForArmor(armor)
    local armorClass = getArmorClass(types.Armor.records[armor.recordId])
    if armorClass then
        return armorSoundTable[armorClass]
    end
    return nil
end

local function getEquipSoundsforWeapon(weapon)
    if not weapon or not weapon.recordId then
        return nil
    end
    local weaponType = weapon.type.records[weapon.recordId].type
    return weaponSoundTable[weaponType]
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

local function getBestRingSlot(actorEquipment, itemObject)
    if not actorEquipment then return nil end
    if not itemObject then return nil end
    if not (itemObject.type == types.Clothing) then return nil end

    local record = types.Clothing.records[itemObject.recordId]
    if not record then return nil end
    
    local cType = record.type
    if cType ~= types.Clothing.TYPE.Ring then return nil end

    -- If it's already equipped, equip to the same slot
    if actorEquipment[Actor.EQUIPMENT_SLOT.LeftRing] == itemObject then return Actor.EQUIPMENT_SLOT.LeftRing end
    if actorEquipment[Actor.EQUIPMENT_SLOT.RightRing] == itemObject then return Actor.EQUIPMENT_SLOT.RightRing end

    return actorEquipment[Actor.EQUIPMENT_SLOT.LeftRing] == nil and Actor.EQUIPMENT_SLOT.LeftRing or Actor.EQUIPMENT_SLOT.RightRing
end

local function getEquipmentSlotForClothing(actor, clothing)
    if clothing == nil then return nil end

    local record = types.Clothing.records[clothing.recordId]
    if not record then return nil end
    
    local clothingType = record.type

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
        if actor ~= nil then
            local equipment = types.Actor.getEquipment(actor)
            if equipment then
                return getBestRingSlot(equipment, clothing)
            else
                return types.Actor.EQUIPMENT_SLOT.RightRing
            end
        else
            return types.Actor.EQUIPMENT_SLOT.RightRing
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
    if (not weapon) or (not weapon.recordId) then return nil end

    local weaponType = types.Weapon.records[weapon.recordId].type

    if weaponType == types.Weapon.TYPE.Arrow or weaponType == types.Weapon.TYPE.Bolt then
        return Actor.EQUIPMENT_SLOT.Ammunition
    else
        return Actor.EQUIPMENT_SLOT.CarriedRight
    end
end


local lib = {
    -- Takes an armor record and returns the class of armor.
    -- 'NONE', 'LIGHT', 'MEDIUM', 'HEAVY'
    getArmorClass = getArmorClass,

    -- Calculates the armor rating an armorRecord would have for an actor
    getArmorRatingForActor = function(actor, armorRecord)
        if (not actor) or (not armorRecord) then return nil end

        local class = getArmorClass(armorRecord)
        if (not class) then return nil end
        local skill = getSkillForArmorClass(actor, class)
        if not skill then return nil end
        return math.floor(armorRecord.baseArmor * (skill / 30.0))
    end,

    -- Translates ArmorType to EquipmentSlot
    getEquipmentSlotForArmor = getEquipmentSlotForArmor,

    -- return the equipment slot for a weapon
    -- takes an item object that should be a weapon type.
    getEquipmentSlotForWeapon = getEquipSoundsforWeapon,

    -- Get a suitable equipment slot for any item, if possible. item is an Item GameObject.
    -- actor is optional and is used to calculate the ring slot if supplied.
    getEquipmentSlotForItem = function(item, actor)
        if not item then return nil end

        if item.type == types.Armor then
            return getEquipmentSlotForArmor(item)
        elseif item.type == types.Clothing then
            return getEquipmentSlotForClothing(actor, item)
        elseif item.type == types.Weapon then
            return getEquipmentSlotForWeapon(item)
        elseif item.type == types.Light then
            return Actor.EQUIPMENT_SLOT.CarriedLeft
        elseif item.type == types.Lockpick then
            return Actor.EQUIPMENT_SLOT.CarriedRight
        elseif item.type == types.Probe then
            return Actor.EQUIPMENT_SLOT.CarriedRight
        end

        return nil
    end,

    -- Takes an item object and returns a table with
    -- { equip = string, unequip string }
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

    -- Picks a ring slot to equip a ring in
    -- If the ring is already equipped, the same slot is returned
    -- If theres an empty slot, it will return that
    -- In case of no empty slots it will return RightRing
    getBestRingSlot = getBestRingSlot,

    -- if actor is nil, RightRing is always returned for rings.
    getEquipmentSlotForClothing = getEquipmentSlotForClothing,
}

return lib