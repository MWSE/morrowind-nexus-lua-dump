local core = require('openmw.core')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local types = require('openmw.types')

local isPlayer, self = pcall(require, 'openmw.self')
local _, debug = pcall(require, 'openmw.debug')
local _, ui = pcall(require, 'openmw.ui')

local C = require('scripts.InventoryExtender.util.constants')

local configGlobal = require('scripts.InventoryExtender.config.global')
local storage = require('openmw.storage')
local l10n = core.l10n('InventoryExtender')

local Helpers = {}

local function reverseLookup(enumTable)
    local lookup = {}
    for key, value in pairs(enumTable) do
        lookup[value] = key
    end
    return lookup
end

local weaponTypeNames = reverseLookup(types.Weapon.TYPE)
local armorTypeNames = reverseLookup(types.Armor.TYPE)
local clothingTypeNames = reverseLookup(types.Clothing.TYPE)
local apparatusTypeNames = reverseLookup(types.Apparatus.TYPE)

local armorSlotMap = {
    [types.Armor.TYPE.Helmet] = { types.Actor.EQUIPMENT_SLOT.Helmet },
    [types.Armor.TYPE.Cuirass] = { types.Actor.EQUIPMENT_SLOT.Cuirass },
    [types.Armor.TYPE.Greaves] = { types.Actor.EQUIPMENT_SLOT.Greaves },
    [types.Armor.TYPE.Boots] = { types.Actor.EQUIPMENT_SLOT.Boots },
    [types.Armor.TYPE.LPauldron] = { types.Actor.EQUIPMENT_SLOT.LeftPauldron },
    [types.Armor.TYPE.RPauldron] = { types.Actor.EQUIPMENT_SLOT.RightPauldron },
    [types.Armor.TYPE.LGauntlet] = { types.Actor.EQUIPMENT_SLOT.LeftGauntlet },
    [types.Armor.TYPE.RGauntlet] = { types.Actor.EQUIPMENT_SLOT.RightGauntlet },
    [types.Armor.TYPE.LBracer] = { types.Actor.EQUIPMENT_SLOT.LeftGauntlet },
    [types.Armor.TYPE.RBracer] = { types.Actor.EQUIPMENT_SLOT.RightGauntlet },
    [types.Armor.TYPE.Shield] = { types.Actor.EQUIPMENT_SLOT.CarriedLeft },
}

local clothingSlotMap = {
    [types.Clothing.TYPE.Shirt] = { types.Actor.EQUIPMENT_SLOT.Shirt },
    [types.Clothing.TYPE.Pants] = { types.Actor.EQUIPMENT_SLOT.Pants },
    [types.Clothing.TYPE.Skirt] = { types.Actor.EQUIPMENT_SLOT.Skirt },
    [types.Clothing.TYPE.Robe] = { types.Actor.EQUIPMENT_SLOT.Robe },
    [types.Clothing.TYPE.Shoes] = { types.Actor.EQUIPMENT_SLOT.Boots },
    [types.Clothing.TYPE.Belt] = { types.Actor.EQUIPMENT_SLOT.Belt },
    [types.Clothing.TYPE.Amulet] = { types.Actor.EQUIPMENT_SLOT.Amulet },
    [types.Clothing.TYPE.LGlove] = { types.Actor.EQUIPMENT_SLOT.LeftGauntlet },
    [types.Clothing.TYPE.RGlove] = { types.Actor.EQUIPMENT_SLOT.RightGauntlet },
    [types.Clothing.TYPE.Ring] = {
        types.Actor.EQUIPMENT_SLOT.LeftRing,
        types.Actor.EQUIPMENT_SLOT.RightRing,
    },
}

local windowSettings = nil
Helpers.getWindowSettings = function()
    if windowSettings == nil then
        windowSettings = storage.playerSection('Settings/InventoryExtender/2_WindowOptions')
    end
    return windowSettings
end


Helpers.shallowCopy = function(tbl)
    if type(tbl) ~= 'table' then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = v
    end
    return copy
end

Helpers.deepCopy = function(tbl)
    if type(tbl) ~= 'table' then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == 'table' then
            copy[k] = Helpers.deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

Helpers.deepPrint = function(tbl, indent)
    if type(tbl) ~= 'table' then return tostring(tbl) end
    indent = indent or 0
    local toprint = string.rep(" ", indent) .. "{\n"
    indent = indent + 2 
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent)
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "] = "
        elseif (type(k) == "string") then
            toprint = toprint  .. k ..  " = "   
        end
        if (type(v) == "number") then
            toprint = toprint .. v .. ",\n"
        elseif (type(v) == "string") then
            toprint = toprint .. "\"" .. v .. "\",\n"
        elseif (type(v) == "table") then
            toprint = toprint .. Helpers.deepPrint(v, indent + 2) .. ",\n"
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\",\n"
        end
    end
    toprint = toprint .. string.rep(" ", indent-2) .. "}"
    return toprint
end

Helpers.uiDeepPrint = function(layoutOrElement, lvl)
    lvl = lvl or 0
    local isElement = type(layoutOrElement) == 'userdata'
    local layout = isElement and layoutOrElement.layout or layoutOrElement
    if layout.name then
        print(string.rep('-', lvl), layoutOrElement, layout.name)
    end
    if layout.props then
        print(string.rep(' ', lvl), 'Props:', Helpers.deepPrint(layout.props))
    end
    if layout.userData then
        print(string.rep(' ', lvl), 'UserData:', Helpers.deepPrint(layout.userData))
    end
    if layout.content then
        for _, child in pairs(layout.content) do
            Helpers.uiDeepPrint(child, lvl + 1)
        end
    end
end

Helpers.forEachInLayout = function(layoutOrElement, func)
    local isElement = type(layoutOrElement) == 'userdata'
    local layout = isElement and layoutOrElement.layout or layoutOrElement
    func(layout)
    if layout.content then
        for _, child in pairs(layout.content) do
            Helpers.forEachInLayout(child, func)
        end
    end
end

Helpers.findInLayout = function(layoutOrElement, predicate)
    local isElement = type(layoutOrElement) == 'userdata'
    local layout = isElement and layoutOrElement.layout or layoutOrElement
    if predicate(layout) then
        return layout
    end
    if layout.content then
        for _, child in pairs(layout.content) do
            local result = Helpers.findInLayout(child, predicate)
            if result then
                return result
            end
        end
    end
    return nil
end

-- Checks if two tables contain the same elements (ignoring order)
Helpers.tableEquals = function(t1, t2)
    if (type(t1) ~= "table" and type(t1) ~= "userdata") or (type(t2) ~= "table" and type(t2) ~= "userdata") then
        return t1 == t2
    end
    if t1.id and t2.id then
        local sameCount = true
        if t1.count and t2.count then
            sameCount = t1.count == t2.count
        end
        return t1.id == t2.id and sameCount
    end
    local t1Keys = {}
    local t2Keys = {}
    for k in pairs(t1) do table.insert(t1Keys, k) end
    for k in pairs(t2) do table.insert(t2Keys, k) end
    table.sort(t1Keys)
    table.sort(t2Keys)
    if #t1Keys ~= #t2Keys then return false end
    for i = 1, #t1Keys do
        if t1Keys[i] ~= t2Keys[i] then return false end
        if not Helpers.tableEquals(t1[t1Keys[i]], t2[t2Keys[i]]) then return false end
    end
    return true
end

Helpers.mapEquals = function(m1, m2)
    for k, v in pairs(m1) do
        if type(v) == 'table' and type(m2[k]) == 'table' then
            if not Helpers.mapEquals(v, m2[k]) then
                return false
            end
        else
            if m2[k] ~= v then
                return false
            end
        end
    end
    for k, v in pairs(m2) do
        if type(v) == 'table' and type(m1[k]) == 'table' then
            if not Helpers.mapEquals(v, m1[k]) then
                return false
            end
        else
            if m1[k] ~= v then
                return false
            end
        end
    end
    return true
end

Helpers.mergeTables = function(t1, t2)
    local merged = Helpers.shallowCopy(t1)
    for k, v in pairs(t2) do
        merged[k] = v
    end
    return merged
end

Helpers.roundToPlaces = function(num, places)
    local mult = 10^(places or 0)
    return math.floor(num * mult + 0.5) / mult
end

Helpers.toLookup = function(list)
    local lookup = {}
    for _, v in ipairs(list) do
        lookup[v] = true
    end
    return lookup
end

Helpers.getCountString = function(count)
    if count == 1 then
        return ''
    elseif count > 999999999 then
        return math.floor(count / 1000000000) .. 'b'
    elseif count > 999999 then
        return math.floor(count / 1000000) .. 'm'
    elseif count > 9999 then
        return math.floor(count / 1000) .. 'k'
    else
        return tostring(count)
    end
end

Helpers.addSeparators = function(number)
    local mode = Helpers.getWindowSettings():get(C.OPT_KEYS.SeparatorsMode)
    local separator
    
    if mode == C.SEPARATOR_OPTS.Comma then
        separator = ','
    elseif mode == C.SEPARATOR_OPTS.Space then
        separator = ' '
    end
    if separator == nil then return tostring(number) end
    
    local _, _, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
    
    -- reverse the int-string and append a comma to all blocks of 3 digits
    int = int:reverse():gsub("(%d%d%d)", "%1" .. separator)
    
    -- reverse the int-string back remove an optional comma and put the 
    -- optional minus and fractional part back
    return minus .. int:reverse():gsub("^" .. separator, "") .. fraction
end


Helpers.getEquippedName = function(actor)
    local name = C.Strings.HAND_TO_HAND
    local selected = actor.type.getEquipment(actor, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if selected then
        name = selected.type.record(selected).name
    end
    return name
end

Helpers.isItemEquipped = function(item, actor, overrides)
    if overrides then
        for i = #overrides, 1, -1 do
            local result = overrides[i].handler(item, actor)
            if result ~= nil then
                return result
            end
        end
    end

    if not actor.type.hasEquipped then return false end
    return actor.type.hasEquipped(actor, item)
end

Helpers.getEquipmentSlots = function (item)
    --TODO: add support for Bardcraft instruments?
    if types.Armor.objectIsInstance(item) then
        return armorSlotMap[item.type.record(item).type]
    end
    
    if types.Clothing.objectIsInstance(item) then
        return clothingSlotMap[item.type.record(item).type]
    end
    
    if types.Weapon.objectIsInstance(item) then
        local weaponType = item.type.record(item).type
        if weaponType == types.Weapon.TYPE.Arrow or weaponType == types.Weapon.TYPE.Bolt then
            return { types.Actor.EQUIPMENT_SLOT.Ammunition }
        end
        return { types.Actor.EQUIPMENT_SLOT.CarriedRight }
    end
    
    return nil
end

Helpers.getEquippedItem = function(slot, actor, overrides)
    --TODO: add support for custom slots for Bardcraft instruments and maybe backpacks?
    if not slot then return nil end
    return types.Actor.getEquipment(actor, slot)
end

Helpers.getEquippedItems = function(slots, actor, overrides)
    local equipped = {}
    if not slots or #slots <= 0 then return equipped end
    for _, slot in ipairs(slots) do
        local item = Helpers.getEquippedItem(slot, actor, overrides)
        if item then table.insert(equipped, item) end
    end
    return equipped
end

Helpers.getWeaponInfo = function(item)
    if not types.Weapon.objectIsInstance(item) then
        return nil
    end
    local record = types.Weapon.records[item.recordId]
    local TYPE = types.Weapon.TYPE
    if record.type == TYPE.Arrow or record.type == TYPE.Bolt then
        return {
            skill = 'marksman',
            soundId = 'ammo',
            class = C.WeaponClass.Ammo,
        }
        
    elseif record.type == TYPE.MarksmanBow then
        return {
            skill = 'marksman',
            soundId = 'weapon bow',
            class = C.WeaponClass.Ranged,
        }

    elseif record.type == TYPE.MarksmanCrossbow then
        return {
            skill = 'marksman',
            soundId = 'weapon crossbow',
            class = C.WeaponClass.Ranged,
        }

    elseif record.type == TYPE.MarksmanThrown then
        return {
            skill = 'marksman',
            soundId = 'weapon blunt',
            class = C.WeaponClass.Thrown,
        }

    elseif record.type == TYPE.AxeOneHand then
        return {
            skill = 'axe',
            soundId = 'weapon blunt',
            class = C.WeaponClass.Melee,
            isTwoHanded = false,
        }

    elseif record.type == TYPE.AxeTwoHand then
        return {
            skill = 'axe',
            soundId = 'weapon blunt',
            class = C.WeaponClass.Melee,
            isTwoHanded = true,
        }

    elseif record.type == TYPE.BluntOneHand then
        return {
            skill = 'bluntweapon',
            soundId = 'weapon blunt',
            class = C.WeaponClass.Melee,
            isTwoHanded = false,
        }

    elseif record.type == TYPE.BluntTwoClose or record.type == TYPE.BluntTwoWide then
        return {
            skill = 'bluntweapon',
            soundId = 'weapon blunt',
            class = C.WeaponClass.Melee,
            isTwoHanded = true,
        }

    elseif record.type == TYPE.LongBladeOneHand then
        return {
            skill = 'longblade',
            soundId = 'weapon longblade',
            class = C.WeaponClass.Melee,
            isTwoHanded = false,
        }

    elseif record.type == TYPE.LongBladeTwoHand then
        return {
            skill = 'longblade',
            soundId = 'weapon longblade',
            class = C.WeaponClass.Melee,
            isTwoHanded = true,
        }

    elseif record.type == TYPE.ShortBladeOneHand then
        return {
            skill = 'shortblade',
            soundId = 'weapon shortblade',
            class = C.WeaponClass.Melee,
            isTwoHanded = false,
        }

    elseif record.type == TYPE.SpearTwoWide then
        return {
            skill = 'spear',
            soundId = 'weapon spear',
            class = C.WeaponClass.Melee,
            isTwoHanded = true,
        }
        
    end
end

Helpers.getWeaponDamage = function(item)
    if not types.Weapon.objectIsInstance(item) then
        return nil
    end

    local record = item.type.record(item)
    return math.max(record.chopMaxDamage, record.slashMaxDamage, record.thrustMaxDamage)
end

Helpers.getWeaponTypeLabel = function(item)
    if not types.Weapon.objectIsInstance(item) then
        return nil
    end

    local enumName = weaponTypeNames[item.type.record(item).type]
    return enumName and l10n('Type_' .. enumName) or nil
end

Helpers.getArmorSlotLabel = function(item)
    if not types.Armor.objectIsInstance(item) then
        return nil
    end

    local enumName = armorTypeNames[item.type.record(item).type]
    return enumName and l10n('Type_' .. enumName) or nil
end

Helpers.getClothingTypeLabel = function(item)
    if not types.Clothing.objectIsInstance(item) then
        return nil
    end

    local enumName = clothingTypeNames[item.type.record(item).type]
    return enumName and l10n('Type_' .. enumName) or nil
end

Helpers.getApparatusTypeLabel = function(item)
    if not types.Apparatus.objectIsInstance(item) then
        return nil
    end

    local enumName = apparatusTypeNames[item.type.record(item).type]
    return enumName and l10n('Type_' .. enumName) or nil
end

Helpers.getItemTypeLabel = function(item)
    local specificType = Helpers.getWeaponTypeLabel(item)
        or Helpers.getArmorSlotLabel(item)
        or Helpers.getClothingTypeLabel(item)
        or Helpers.getApparatusTypeLabel(item)
    if specificType then
        return specificType
    end

    if types.Book.objectIsInstance(item) then
        if item.type.record(item).enchant then
            return l10n('Type_Scroll')
        end
        return l10n('Type_Book')
    elseif types.Potion.objectIsInstance(item) then
        return l10n('Type_Consumable')
    elseif types.Ingredient.objectIsInstance(item) then
        return l10n('Type_Ingredient')
    elseif types.Lockpick.objectIsInstance(item) then
        return l10n('Type_Lockpick')
    elseif types.Probe.objectIsInstance(item) then
        return l10n('Type_Probe')
    elseif types.Light.objectIsInstance(item) then
        return l10n('Type_Light')
    elseif types.Repair.objectIsInstance(item) then
        return l10n('Type_RepairTool')
    elseif types.Miscellaneous.objectIsInstance(item) then
        if item.type.record(item).isKey then
            return l10n('Type_Key')
        end
        return l10n('Type_Misc')
    end

    return nil
end

Helpers.getArmorClassLabel = function(item)
    if not types.Armor.objectIsInstance(item) then
        return nil
    end

    local skill = I.Combat.getArmorSkill(item)
    if skill == 'lightarmor' then
        return l10n('Class_Light')
    elseif skill == 'mediumarmor' then
        return l10n('Class_Medium')
    elseif skill == 'heavyarmor' then
        return l10n('Class_Heavy')
    end

    return core.getGMST('sSkill' .. skill)
end

Helpers.getArmorRating = function(item, actor)
    if not types.Armor.objectIsInstance(item) then
        return nil
    end

    local effectiveActor = actor or (isPlayer and self) or nil
    if effectiveActor then
        return math.floor(I.Combat.getEffectiveArmorRating(item, effectiveActor))
    end

    return item.type.record(item).baseArmor
end

Helpers.getConditionPercent = function(item)
    if not types.Item.objectIsInstance(item) then
        return nil
    end

    local itemData = types.Item.itemData(item)
    local condition = itemData.condition
    if condition == nil or condition == -1 then
        return nil
    end

    local itemRecord = item.type.record(item)
    local conditionMax
    if itemRecord.health then
        conditionMax = util.round(itemRecord.health)
    elseif itemRecord.maxCondition then
        conditionMax = util.round(itemRecord.maxCondition)
    elseif itemRecord.duration then
        conditionMax = util.round(itemRecord.duration)
    end

    if not conditionMax or conditionMax <= 0 then
        return nil
    end

    return util.round((condition / conditionMax) * 100)
end

Helpers.getConditionPercentLabel = function(item)
    local percent = Helpers.getConditionPercent(item)
    if percent == nil then
        return '-'
    end
    return tostring(percent) .. '%'
end

Helpers.getItemName = function(item)
    local soul = item.type.itemData(item).soul
    local baseName = item.type.record(item).name
    if soul then
        local soulRecord = types.Creature.records[soul]
        if soulRecord then
            return baseName .. ' (' .. soulRecord.name .. ')'
        end
    end
    return baseName
end

Helpers.getItemValue = function(item)
    if Helpers.isGold(item) then
        return 1
    end

    if item.type.record(item).isKey then
        return 0
    end

    local soul = item.type.itemData(item).soul
    local baseValue = item.type.record(item).value
    if not soul then return baseValue end

    local soulRecord = types.Creature.records[soul]
    local soulValue = soulRecord and soulRecord.soulValue or 0
    if configGlobal.gameplay.b_SoulGemValueRebalance then
        soulValue = 0.0001 * (soulValue ^ 3) + 2 * soulValue

        if item.recordId:lower() == 'misc_soulgem_azura' then
            return baseValue + math.modf(soulValue)
        else
            return math.modf(soulValue)
        end
    else
        return baseValue * soulValue
    end
end

Helpers.isSoulGem = function(item)
    return types.Miscellaneous.objectIsInstance(item) and item.recordId:lower():find('^misc_soulgem')
end

Helpers.getSoulGemCapacity = function(item)
    if not Helpers.isSoulGem(item) then
        return nil
    end

    local record = item.type.record(item)
    return record.value * core.getGMST('fSoulGemMult')
end

Helpers.getWeaponRangeInFeet = function(item)
    if not types.Weapon.objectIsInstance(item) then
        return 0
    end
    local record = types.Weapon.records[item.recordId]
    local reach = record.reach or 0
    local unitsPerFoot = 21.33333333
    return core.getGMST('fCombatDistance') * reach / unitsPerFoot
end

Helpers.doesItemFit = function(item, container, count)
    if not container or not types.Container.objectIsInstance(container) then
        return true
    end
    local itemWeight = item.type.record(item).weight * (count or item.count)
    local contEncumbrance = types.Container.getEncumbrance(container)
    local contCapacity = types.Container.getCapacity(container)
    return (contEncumbrance + itemWeight) <= contCapacity
end

Helpers.itemDataEquals = function(a, b)
    if not types.Item.objectIsInstance(a) or not types.Item.objectIsInstance(b) then
        return false
    end

    local itemDataA = types.Item.itemData(a)
    local itemDataB = types.Item.itemData(b)

    local fieldsToCheck = {
        'condition',
        'enchantmentCharge',
        'soul',
    }

    for _, field in ipairs(fieldsToCheck) do
        if itemDataA[field] ~= itemDataB[field] then
            return false
        end
    end
    return true
end

Helpers.itemCanStack = function(a, b)
    if Helpers.isGold(a) and Helpers.isGold(b) then
        return true
    end
    if a.recordId:lower() ~= b.recordId:lower() then
        return false
    end
    if not Helpers.itemDataEquals(a, b) then
        return false
    end
    if a.type.record(a).mwscript or b.type.record(b).mwscript then
        return false
    end
    return true
end

Helpers.getMerchantItems = function(npc)
    local unmerged = {}
    local carried = npc.type.inventory(npc):getAll()
    for _, item in ipairs(carried) do
        table.insert(unmerged, item)
    end
    local success, nearby = pcall(require, 'openmw.nearby')
    if success then
        for _, item in ipairs(nearby.items) do
            if item.owner.recordId == npc.recordId then
                table.insert(unmerged, item)
            end
        end
        for _, container in ipairs(nearby.containers) do
            if container.owner.recordId == npc.recordId then
                local inv = container.type.inventory(container)
                local contItems = inv:getAll()
                for _, item in ipairs(contItems) do
                    table.insert(unmerged, item)
                end
            end
        end
    end

    local virtualMerged = {}
    for _, item in ipairs(unmerged) do
        local key = item.recordId:lower()
        if virtualMerged[key] then
            local existing = false
            for _, virtualStack in ipairs(virtualMerged[key]) do
                if Helpers.itemCanStack(item, virtualStack.stacks[1]) then
                    existing = true
                    table.insert(virtualStack.stacks, item)
                    virtualStack.totalCount = virtualStack.totalCount + item.count
                    break
                end
            end
            if not existing then
                table.insert(virtualMerged[key], {
                    stacks = { item },
                    totalCount = item.count,
                })
            end
        else
            virtualMerged[key] = { {
                stacks = { item },
                totalCount = item.count,
            } }
        end
    end

    return virtualMerged
end

Helpers.isGold = function(item)
    local id = type(item) == 'string' and item:lower() or item.recordId:lower()
    return id == 'gold_001' or id == 'gold_005' or id == 'gold_010' or id == 'gold_025' or id == 'gold_100'
end

Helpers.isBoundItem = function(item)
    return C.BoundItemIDs[item.recordId:lower()] ~= nil
end

Helpers.getItemSound = function(item, upOrDown)
    local itemRecord = item.type.record(item)
    local itemStr
    if types.Armor.objectIsInstance(item) then
        local skill = I.Combat.getArmorSkill(item)
        if skill == 'lightarmor' then itemStr = 'armor light'
        elseif skill == 'mediumarmor' then itemStr = 'armor medium'
        else itemStr = 'armor heavy' end
    elseif types.Miscellaneous.objectIsInstance(item) then
        itemStr = Helpers.isGold(item) and 'gold' or 'misc'
    elseif types.Apparatus.objectIsInstance(item) then
        itemStr = 'apparatus'
    elseif types.Book.objectIsInstance(item) then
        itemStr = 'book'
    elseif types.Clothing.objectIsInstance(item) then
        itemStr = itemRecord.type == types.Clothing.TYPE.Ring and 'ring' or 'clothes'
    elseif types.Ingredient.objectIsInstance(item) then
        itemStr = 'ingredient'
    elseif types.Light.objectIsInstance(item) then
        itemStr = 'misc'
    elseif types.Lockpick.objectIsInstance(item) then
        itemStr = 'lockpick'
    elseif types.Potion.objectIsInstance(item) then
        itemStr = 'potion'
    elseif types.Probe.objectIsInstance(item) then
        itemStr = 'probe'
    elseif types.Repair.objectIsInstance(item) then
        itemStr = 'repair'
    elseif types.Weapon.objectIsInstance(item) then
        local weaponInfo = Helpers.getWeaponInfo(item)
        itemStr = weaponInfo and weaponInfo.soundId
    end

    if not itemStr then return nil end

    return 'item ' .. itemStr .. ' ' .. upOrDown
end

local FATIGUE_BASE = core.getGMST('fFatigueBase')
local FATIGUE_MULT = core.getGMST('fFatigueMult')
Helpers.getFatigueTerm = function(actor)
    local fatigueStat = actor.type.stats.dynamic.fatigue(actor)
    local normalizedFatigue
    if fatigueStat.base == 0 then
        normalizedFatigue = 1
    else
        normalizedFatigue = math.max(0, fatigueStat.current / fatigueStat.base)
    end

    return FATIGUE_BASE - FATIGUE_MULT * (1 - normalizedFatigue)
end

if isPlayer then
    local magicka = self.type.stats.dynamic.magicka(self)
    local willpower = self.type.stats.attributes.willpower(self)
    local luck = self.type.stats.attributes.luck(self)

    local chargeMult = {
        [core.magic.ENCHANTMENT_TYPE.CastOnStrike] = core.getGMST('iMagicItemChargeStrike'),
        [core.magic.ENCHANTMENT_TYPE.CastOnUse] = core.getGMST('iMagicItemChargeUse'),
        [core.magic.ENCHANTMENT_TYPE.CastOnce] = core.getGMST('iMagicItemChargeOnce'),
        [core.magic.ENCHANTMENT_TYPE.ConstantEffect] = core.getGMST('iMagicItemChargeConst'),
    }

    Helpers.getEnchantMaxCharge = function(enchantment)
        local cost = math.floor(Helpers.getBaseSpellCost(enchantment.id, true) + 0.5)
        return cost * chargeMult[enchantment.type]
    end

    Helpers.getBaseSpellCost = function(spellId, isEnchant)
        local cost = 0

        local spellRecord
        if isEnchant then
            spellRecord = core.magic.enchantments.records[spellId]
        else
            spellRecord = core.magic.spells.records[spellId]
        end
        if not spellRecord then return cost end

        if not spellRecord.autocalcFlag then
            return spellRecord.cost
        end

        for _, effect in ipairs(spellRecord.effects) do
            local minMagnitude, maxMagnitude = 1, 1
            local baseEffect = effect.effect

            if baseEffect.hasMagnitude then
                minMagnitude = effect.magnitudeMin
                maxMagnitude = effect.magnitudeMax
            end
            if not isEnchant then
                minMagnitude = math.max(1, minMagnitude)
                maxMagnitude = math.max(1, maxMagnitude)
            end

            local x = baseEffect.hasDuration and effect.duration or 1
            if not baseEffect.isAppliedOnce then
                x = math.max(x, 1)
            end
            x = x * 0.1 * baseEffect.baseCost
            x = x * 0.5 * (effect.magnitudeMin + effect.magnitudeMax)
            x = x + 0.05 * baseEffect.baseCost * effect.area
            if effect.range == core.magic.RANGE.Target then
                x = x * 1.5
            end
            x = x * core.getGMST('fEffectCostMult')
            x = math.max(0, x)

            cost = cost + x
        end

        return cost
    end

    Helpers.getModifiedSpellCost = function(spellId, isEnchant)
        local baseCost = Helpers.getBaseSpellCost(spellId, isEnchant)

        local cost = baseCost

        if isEnchant then
            local x = 0.01 * (110 - self.type.stats.skills.enchant(self).modified)
            cost = math.floor(x * cost)
            cost = math.max(cost, 1)
        end

        return cost
    end

    Helpers.getSpellCastChance = function(spellId)
        local spellRecord = core.magic.spells.records[spellId]
        if not spellRecord then return 0 end

        if debug.isGodMode() then
            return 100
        end

        local activeEffects = self.type.activeEffects(self)
        if activeEffects:getEffect(core.magic.EFFECT_TYPE.Silence).magnitude > 0 then 
            return 0
        end

        if not (spellRecord.type == core.magic.SPELL_TYPE.Spell or spellRecord.type == core.magic.SPELL_TYPE.Power) then
            return 100
        end

        if spellRecord.type == core.magic.SPELL_TYPE.Power then
            return self.type.spells(self):canUsePower(spellId) and 100 or 0 -- Powers can always be used if not on cooldown
        end

        if spellRecord.type == core.magic.SPELL_TYPE.Spell then
            local cost = 0

            local y = math.huge
            local lowestSkill = 0
            local effectiveSchool
            for _, effect in ipairs(spellRecord.effects) do
                local baseEffect = effect.effect
                local x = baseEffect.hasDuration and effect.duration or 1
                if not baseEffect.isAppliedOnce then
                    x = math.max(x, 1)
                end
                x = x * 0.1 * baseEffect.baseCost
                x = x * 0.5 * (effect.magnitudeMin + effect.magnitudeMax)
                x = x + 0.05 * baseEffect.baseCost * effect.area
                if effect.range == core.magic.RANGE.Target then
                    x = x * 1.5
                end
                x = x * core.getGMST('fEffectCostMult')

                cost = cost + x

                local s = 2 * self.type.stats.skills[baseEffect.school](self).modified
                if (s - x) < y then
                    y = s - x
                    effectiveSchool = baseEffect.school
                    lowestSkill = s
                end
            end

            if not spellRecord.autocalcFlag then
                cost = spellRecord.cost
            end

            if spellRecord.alwaysSucceedFlag then
                return 100, effectiveSchool
            end

            if magicka.current < cost then
                return 0, effectiveSchool
            end

            local castBonus = -activeEffects:getEffect(core.magic.EFFECT_TYPE.Sound).magnitude
            local castChance = (lowestSkill - util.round(cost) + castBonus + 0.2 * willpower.modified + 0.1 * luck.modified) * Helpers.getFatigueTerm()

            return math.floor(util.clamp(castChance, 0.0, 100.0)), effectiveSchool
        end
    end

    local magnitudeMap = {
        [C.Magic.MagnitudeDisplayType.TIMES_INT] = {
            fortifymaximummagicka = true,
        },
        [C.Magic.MagnitudeDisplayType.FEET] = {
            telekinesis = true,
            detectanimal = true,
            detectenchantment = true,
            detectkey = true,
        },
        [C.Magic.MagnitudeDisplayType.LEVEL] = {
            commandcreature = true,
            commandhumanoid = true,
        },
        [C.Magic.MagnitudeDisplayType.PERCENTAGE] = {
            chameleon = true,
            blind = true,
            dispel = true,
            reflect = true,
        },
    }

    Helpers.getEffectMagnitudeDisplayType = function(effect)
        if (not effect.maxMagnitude or not effect.minMagnitude) and not effect.hasMagnitude then
            return C.Magic.MagnitudeDisplayType.NONE
        end
        if magnitudeMap[C.Magic.MagnitudeDisplayType.TIMES_INT][effect.id] then
            return C.Magic.MagnitudeDisplayType.TIMES_INT
        end
        if magnitudeMap[C.Magic.MagnitudeDisplayType.FEET][effect.id] then
            return C.Magic.MagnitudeDisplayType.FEET
        end
        if magnitudeMap[C.Magic.MagnitudeDisplayType.LEVEL][effect.id] then
            return C.Magic.MagnitudeDisplayType.LEVEL
        end
        if magnitudeMap[C.Magic.MagnitudeDisplayType.PERCENTAGE][effect.id] or
            effect.id:find('^weakness') or 
            effect.id:find('^resist') then
            return C.Magic.MagnitudeDisplayType.PERCENTAGE
        end
        return C.Magic.MagnitudeDisplayType.POINTS
    end

    Helpers.createDurationString = function(duration)
        local l10n = core.l10n('Interface')

        local string = ''

        if duration < 1.0 then
            string = string .. l10n('DurationSecond', { seconds = 0 })
            return string
        end

        local secondsPerMinute = 60
        local secondsPerHour = secondsPerMinute * 60
        local secondsPerDay = secondsPerHour * 24
        local secondsPerMonth = secondsPerDay * 30
        local secondsPerYear = secondsPerDay * 365

        local fullDuration = math.floor(duration)
        local units = 0
        local years = math.floor(fullDuration / secondsPerYear)
        local months = math.floor((fullDuration % secondsPerYear) / secondsPerMonth)
        local days = math.floor((fullDuration % secondsPerYear % secondsPerMonth) / secondsPerDay)
        local hours = math.floor((fullDuration % secondsPerDay) / secondsPerHour)
        local minutes = math.floor((fullDuration % secondsPerHour) / secondsPerMinute)
        local seconds = fullDuration % secondsPerMinute

        if years > 0 then
            units = units + 1
            string = string .. l10n('DurationYear', { years = years })
        end
        if months > 0 then
            units = units + 1
            string = string .. l10n('DurationMonth', { months = months })
        end
        if units < 2 and days > 0 then
            units = units + 1
            string = string .. l10n('DurationDay', { days = days })
        end
        if units < 2 and hours > 0 then
            units = units + 1
            string = string .. l10n('DurationHour', { hours = hours })
        end
        if units >= 2 then
            return string
        end
        if minutes > 0 then
            string = string .. l10n('DurationMinute', { minutes = minutes })
        end
        if seconds > 0 then
            string = string .. l10n('DurationSecond', { seconds = seconds })
        end

        return string
    end

    Helpers.createActiveEffectString = function(activeSpellEffect, spellName)
        local string = spellName or ''
        if activeSpellEffect.affectedSkill then
            string = string .. ' (' .. core.stats.Skill.records[activeSpellEffect.affectedSkill].name .. ')' 
        end
        if activeSpellEffect.affectedAttribute then
            string = string .. ' (' .. core.stats.Attribute.records[activeSpellEffect.affectedAttribute].name .. ')' 
        end

        local magnitudeType = Helpers.getEffectMagnitudeDisplayType(activeSpellEffect)
        if magnitudeType == C.Magic.MagnitudeDisplayType.TIMES_INT then
            string = string .. ' ' .. Helpers.roundToPlaces(activeSpellEffect.magnitudeThisFrame / 10.0, 1) .. C.Strings.X_TIMES_INT
        elseif magnitudeType ~= C.Magic.MagnitudeDisplayType.NONE then
            string = string .. ': ' .. tostring(math.floor(activeSpellEffect.magnitudeThisFrame))
            if magnitudeType == C.Magic.MagnitudeDisplayType.PERCENTAGE then
                string = string .. C.Strings.PERCENT
            elseif magnitudeType == C.Magic.MagnitudeDisplayType.FEET then
                string = string .. ' ' .. C.Strings.FEET
            elseif magnitudeType == C.Magic.MagnitudeDisplayType.LEVEL then
                string = string .. ' '
                if activeSpellEffect.magnitudeThisFrame > 1 then
                    string = string .. C.Strings.LEVELS
                else
                    string = string .. C.Strings.LEVEL
                end
            else
                string = string .. ' '
                if activeSpellEffect.magnitudeThisFrame > 1 then
                    string = string .. C.Strings.POINTS
                else
                    string = string .. C.Strings.POINT
                end
            end
        end

        if activeSpellEffect.durationLeft and activeSpellEffect.durationLeft > 0 then
            string = string .. ' ' .. C.Strings.DURATION .. ': ' .. Helpers.createDurationString(activeSpellEffect.durationLeft)
        end

        return string
    end

    Helpers.getMagicEffectString = function(effectParams)
        local effect = core.magic.effects.records[effectParams.id]
        if not effect then
            effect = I.MagicWindow and I.MagicWindow.Spells.getCustomEffect(effectParams.id)
            if not effect then
                return ''
            end
        end

        local affectedSkill = effectParams.affectedSkill
        local affectedAttribute = effectParams.affectedAttribute

        local string

        local TYPE = core.magic.EFFECT_TYPE
        if (affectedSkill or affectedAttribute) then
            if effect.id == TYPE.AbsorbAttribute or effect.id == TYPE.AbsorbSkill then
                string = C.Strings.ABSORB
            elseif effect.id == TYPE.DamageAttribute or effect.id == TYPE.DamageSkill then
                string = C.Strings.DAMAGE
            elseif effect.id == TYPE.DrainAttribute or effect.id == TYPE.DrainSkill then
                string = C.Strings.DRAIN
            elseif effect.id == TYPE.FortifyAttribute or effect.id == TYPE.FortifySkill then
                string = C.Strings.FORTIFY
            elseif effect.id == TYPE.RestoreAttribute or effect.id == TYPE.RestoreSkill then
                string = C.Strings.RESTORE
            end
        end

        if not string then
            string = effect.name
        end

        if affectedSkill then
            local skill = core.stats.Skill.records[affectedSkill]
            string = string .. ' ' .. skill.name
        elseif affectedAttribute then
            local attribute = core.stats.Attribute.records[affectedAttribute]
            string = string .. ' ' .. attribute.name
        end

        return string
    end

    local function getKnownAlchemyEffectCount(item)
        if not self or not self.type or not self.type.stats or not self.type.stats.skills or not self.type.stats.skills.alchemy then
            return 0
        end

        local alchemy = self.type.stats.skills.alchemy(self).base
        local threshold = core.getGMST('fWortChanceValue')
        local visibleEffectCount = math.floor(alchemy / threshold)
        if types.Potion.objectIsInstance(item) then
            visibleEffectCount = visibleEffectCount * 2
        end
        return visibleEffectCount
    end

    Helpers.getTooltipMagicEffectEntries = function(item)
        local itemRecord = item.type.record(item)
        local effectsToShow = {}
        local enchantment

        if itemRecord.enchant then
            enchantment = core.magic.enchantments.records[itemRecord.enchant]
        end

        if enchantment then
            local override = I.MagicWindow and I.MagicWindow.Spells.getCustomSpell(itemRecord.enchant)
            for _, effect in ipairs(override and override.effects or enchantment.effects) do
                table.insert(effectsToShow, {
                    effect = effect,
                    visible = true,
                    text = Helpers.createSpellEffectString(effect, enchantment.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect),
                })
            end
        elseif types.Potion.objectIsInstance(item) or types.Ingredient.objectIsInstance(item) then
            local visibleEffectCount = getKnownAlchemyEffectCount(item)
            for i, effect in ipairs(itemRecord.effects) do
                local isVisible = i <= visibleEffectCount
                local effectText = nil
                if isVisible then
                    if types.Potion.objectIsInstance(item) then
                        effectText = Helpers.createSpellEffectString(effect, false, true)
                    else
                        effectText = Helpers.getMagicEffectString(effect)
                    end
                end

                table.insert(effectsToShow, {
                    effect = effect,
                    visible = isVisible,
                    text = effectText,
                })
            end
        end

        return effectsToShow
    end

    Helpers.getItemSearchText = function(item)
        local searchParts = { Helpers.getItemName(item) }

        for _, effectData in ipairs(Helpers.getTooltipMagicEffectEntries(item)) do
            if effectData.visible and effectData.text and effectData.text ~= '' then
                table.insert(searchParts, effectData.text)
            end
        end

        return table.concat(searchParts, '\n')
    end

    Helpers.effectListContainsString = function(effectsWithParams, searchString)
        for _, effectParams in ipairs(effectsWithParams) do
            local string = Helpers.getMagicEffectString(effectParams)
            if string:lower():find(searchString:lower(), 1, true) then
                return true
            end
        end
        return false
    end

    Helpers.effectListContainsSchool = function(effectsWithParams, schoolFilter)
        for _, effectParams in ipairs(effectsWithParams) do
            local effect = effectParams.effect
            if effect and effect.school and effect.school:lower() == schoolFilter:lower() then
                return true
            end
        end
        return false
    end

    Helpers.createSpellEffectString = function(effectParams, isConstant, isPotion)
        local effect = core.magic.effects.records[effectParams.id]
        local isCustom = false
        if not effect then
            effect = I.MagicWindow and I.MagicWindow.Spells.getCustomEffect(effectParams.id)
            if not effect then
                return ''
            end
            isCustom = true
        end
        
        local string = Helpers.getMagicEffectString(effectParams)

        if (effectParams.magnitudeMin or effectParams.magnitudeMax) and effect.hasMagnitude then
            local magnitudeType
            if isCustom then
                magnitudeType = effect.magnitudeType
            else
                magnitudeType = Helpers.getEffectMagnitudeDisplayType(effect)
            end

            if magnitudeType == C.Magic.MagnitudeDisplayType.TIMES_INT then
                string = string .. ' ' .. Helpers.roundToPlaces(effectParams.magnitudeMin / 10.0, 1)
                if effectParams.magnitudeMin ~= effectParams.magnitudeMax then
                    string = string .. ' ' .. C.Strings.TO .. ' ' .. Helpers.roundToPlaces(effectParams.magnitudeMax / 10.0, 1)
                end
                string = string .. C.Strings.X_TIMES_INT
            elseif magnitudeType ~= C.Magic.MagnitudeDisplayType.NONE then
                string = string .. ' ' .. tostring(effectParams.magnitudeMin)
                if effectParams.magnitudeMin ~= effectParams.magnitudeMax then
                    string = string .. ' ' .. C.Strings.TO .. ' ' .. tostring(effectParams.magnitudeMax)
                end

                if magnitudeType == C.Magic.MagnitudeDisplayType.PERCENTAGE then
                    string = string .. C.Strings.PERCENT
                elseif magnitudeType == C.Magic.MagnitudeDisplayType.FEET then
                    string = string .. ' ' .. C.Strings.FEET
                elseif magnitudeType == C.Magic.MagnitudeDisplayType.LEVEL then
                    string = string .. ' '
                    if effectParams.magnitudeMin == effectParams.magnitudeMax and math.abs(effectParams.magnitudeMin) == 1 then
                        string = string .. C.Strings.LEVEL
                    else
                        string = string .. C.Strings.LEVELS
                    end
                else -- POINTS
                    string = string .. ' '
                    if effectParams.magnitudeMin == effectParams.magnitudeMax and math.abs(effectParams.magnitudeMin) == 1 then
                        string = string .. C.Strings.POINT
                    else
                        string = string .. C.Strings.POINTS
                    end
                end
            end
        end

        if not isConstant then
            local duration = effectParams.duration or 0

            if not effect.isAppliedOnce then
                duration = math.max(1, duration)
            end

            if duration > 0 and effect.hasDuration then
                string = string .. ' ' .. C.Strings.FOR .. ' ' .. tostring(duration) .. ' '
                if duration == 1 then
                    string = string .. C.Strings.SECOND
                else
                    string = string .. C.Strings.SECONDS
                end
            end

            if effectParams.area > 0 then
                string = string .. ' ' .. C.Strings.IN .. ' ' .. tostring(effectParams.area) .. ' ' .. C.Strings.FOOT_AREA
            end

            if not isPotion then
                string = string .. ' ' .. C.Strings.ON .. ' '
                if effectParams.range == core.magic.RANGE.Self then
                    string = string .. C.Strings.RANGE_SELF
                elseif effectParams.range == core.magic.RANGE.Touch then
                    string = string .. C.Strings.RANGE_TOUCH
                else
                    string = string .. C.Strings.RANGE_TARGET
                end
            end
        end

        return string
    end

    Helpers.scaleColor = function(color, scale)
        return util.color.rgb(util.clamp(color.r * scale, 0, 1), util.clamp(color.g * scale, 0, 1), util.clamp(color.b * scale, 0, 1))
    end

    Helpers.blendColors = function(color1, color2, blend)
        return util.color.rgb(
            util.clamp(color1.r * (1 - blend) + color2.r * blend, 0, 1),
            util.clamp(color1.g * (1 - blend) + color2.g * blend, 0, 1),
            util.clamp(color1.b * (1 - blend) + color2.b * blend, 0, 1)
        )
    end

    Helpers.setInteractiveColor = function(layout)
        layout = layout.layout or layout
        local userData = layout.userData or {}
        Helpers.forEachInLayout(layout, function(l)
            if l.userData and l.userData.colorable then
                local color
                if userData.active then
                    if userData.pressed then
                        color = C.Colors.ACTIVE_PRESSED
                    elseif userData.hovering then
                        color = C.Colors.ACTIVE_LIGHT
                    else
                        color = C.Colors.ACTIVE
                    end
                elseif userData.disabled then
                    if userData.pressed then
                        color = C.Colors.DISABLED_PRESSED
                    elseif userData.hovering then
                        color = C.Colors.DISABLED_LIGHT
                    else
                        color = C.Colors.DISABLED
                    end
                else
                    if userData.pressed then
                        color = l.userData.pressColor or C.Colors.DEFAULT_PRESSED
                    elseif userData.hovering then
                        color = l.userData.hoverColor or C.Colors.DEFAULT_LIGHT
                    else
                        color = l.userData.baseColor or C.Colors.DEFAULT
                    end
                end

                l.props = l.props or {}
                if l.type == ui.TYPE.Text or l.type == ui.TYPE.TextEdit or (l.template and (l.template.type == ui.TYPE.Text or l.template.type == ui.TYPE.TextEdit)) then
                    l.props.textColor = color
                elseif l.type == ui.TYPE.Image or (l.template and l.template.type == ui.TYPE.Image) then
                    l.props.color = color
                end
            end

            if l.userData and l.userData.opacityStates then
                local states = l.userData.opacityStates
                local alpha
                if userData.active then
                    if userData.pressed then
                        alpha = states.activePressed or states.activeHover or states.active or states.default
                    elseif userData.hovering then
                        alpha = states.activeHover or states.active or states.hover or states.default
                    else
                        alpha = states.active or states.default
                    end
                elseif userData.disabled then
                    if userData.pressed then
                        alpha = states.disabledPressed or states.disabledHover or states.disabled or states.default
                    elseif userData.hovering then
                        alpha = states.disabledHover or states.disabled or states.hover or states.default
                    else
                        alpha = states.disabled or states.default
                    end
                else
                    if userData.pressed then
                        alpha = states.pressed or states.hover or states.default
                    elseif userData.hovering then
                        alpha = states.hover or states.default
                    else
                        alpha = states.default
                    end
                end

                l.props = l.props or {}
                l.props.alpha = alpha
            end
        end)
    end
end

return Helpers