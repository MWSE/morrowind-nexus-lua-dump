local storage = require('openmw.storage')
local types   = require('openmw.types')
local core    = require('openmw.core')
local BL      = require('scripts.DaedraUseBoundEquipment.blacklists')

local daedraIdBlacklist = {}
local weaponIdBlacklist = {}
local armorIdBlacklist = {}
local levelledDaedraIdList = {}

local function log(message)
    if storage.playerSection('SettingsGroup_AR_DUBE'):get('DebugSetting') then
        print(message)
    end
end

local function logIdList(idList)
    if storage.playerSection('SettingsGroup_AR_DUBE'):get('DebugSetting') then
        local count = 0
        for id, value in pairs(idList) do
            print(id)
            count = count + 1
        end
        print('Count = ' .. count)
    end
end

local function convertIdListToLowerCase(idList)
    local lowerCaseIdList = {}
    for id, value in pairs(idList) do
        lowerCaseIdList[id:lower()] = value
    end
    return lowerCaseIdList
end

local function getLevelledDaedraIdList()
    local idList = {}
    for indR, lcRecord in ipairs(types.LevelledCreature.records) do
        for indI, llItem in ipairs(lcRecord.creatures) do
            local creatureRecord = types.Creature.record(llItem.id) -- Creature or NPC id
            if creatureRecord
                and creatureRecord.type == types.Creature.TYPE.Daedra
            then
                idList[llItem.id] = true
            end
        end
    end
    return idList
end

local function initData()
    log('Init Data')

    daedraIdBlacklist = convertIdListToLowerCase(BL.daedraAnyCaseIdBlacklist)
    log('Daedra Id Blacklist:')
    logIdList(daedraIdBlacklist)

    weaponIdBlacklist = convertIdListToLowerCase(BL.weaponAnyCaseIdBlacklist)
    log('Weapon Id Blacklist:')
    logIdList(weaponIdBlacklist)

    armorIdBlacklist = convertIdListToLowerCase(BL.armorAnyCaseIdBlacklist)
    log('Armor Id Blacklist:')
    logIdList(armorIdBlacklist)

    levelledDaedraIdList = getLevelledDaedraIdList()
    log('Levelled Daedra Id List:')
    logIdList(levelledDaedraIdList)
end

local function getEquipmentInfo(equipment)
    local settings = storage.playerSection('SettingsGroup_AR_DUBE')
    if types.Armor.objectIsInstance(equipment) then
        return {
            typeName = 'Armor',
            isBlacklisted = armorIdBlacklist[equipment.recordId],
            removingChance = settings:get('ChanceOfRemovingArmorSetting')
        }
    elseif types.Weapon.objectIsInstance(equipment) then
        if equipment.type.record(equipment.recordId).type == types.Weapon.TYPE.Arrow then
            return {
                typeName = 'Arrow',
                isBlacklisted = weaponIdBlacklist[equipment.recordId],
                removingChance = settings:get('ChanceOfRemovingArrowsAndBoltsSetting')
            }
        elseif equipment.type.record(equipment.recordId).type == types.Weapon.TYPE.Bolt then
            return {
                typeName = 'Bolt',
                isBlacklisted = weaponIdBlacklist[equipment.recordId],
                removingChance = settings:get('ChanceOfRemovingArrowsAndBoltsSetting')
            }
        elseif equipment.type.record(equipment.recordId).type == types.Weapon.TYPE.MarksmanThrown then
            return {
                typeName = 'Throwing Weapon',
                isBlacklisted = weaponIdBlacklist[equipment.recordId],
                removingChance = settings:get('ChanceOfRemovingThrowingWeaponsSetting')
            }
        else
            return {
                typeName = 'Weapon',
                isBlacklisted = weaponIdBlacklist[equipment.recordId],
                removingChance = settings:get('ChanceOfRemovingWeaponsSetting')
            }
        end
    else
        log('Error: Get Equipment Info: Not supported type')
        return {
            typeName = 'Not Supported',
            isBlacklisted = nil,
            removingChance = 0
        }
    end
end

local function processEquipment(equipment)
    local equipmentInfo = getEquipmentInfo(equipment)
    log(equipmentInfo.typeName .. ': ' .. equipment.recordId)

    if equipmentInfo.isBlacklisted then
        if storage.playerSection('SettingsGroup_AR_DUBE'):get('UseBlacklistsSetting') then
            log(equipmentInfo.typeName .. ': Blacklisted: No actions (Use Blacklists = Yes)')
            return
        else
            log(equipmentInfo.typeName .. ': Blacklisted: Ignoring (Use Blacklists = No)')
        end
    end

    log(equipmentInfo.typeName .. ': Count = ' .. equipment.count)
    local removingCount = 0
    for ind = 1, equipment.count do
        local randomValue = math.random(1, 100)
        if equipmentInfo.removingChance >= randomValue then
            log(equipmentInfo.typeName .. ': Removing (Removing Chance = '
                .. equipmentInfo.removingChance .. ' >= Random Value = ' .. randomValue .. ')')
            removingCount = removingCount + 1
        else
            log(equipmentInfo.typeName .. ': No actions (Removing Chance = '
                .. equipmentInfo.removingChance .. ' < Random Value = ' .. randomValue .. ')')
        end
    end
    log(equipmentInfo.typeName .. ': Removing Count = ' .. removingCount)
    if removingCount > 0 then
        core.sendGlobalEvent('removeEquipment', {equipment = equipment, count = removingCount})
    end
end

local function processDaedra(daedra)
    log('Daedra: ' .. daedra.recordId)

    if daedraIdBlacklist[daedra.recordId] then
        if storage.playerSection('SettingsGroup_AR_DUBE'):get('UseBlacklistsSetting') then
            log('Daedra: Blacklisted: No actions (Use Blacklists = Yes)')
            return
        else
            log('Daedra: Blacklisted: Ignoring (Use Blacklists = No)')
        end
    end

    if levelledDaedraIdList[daedra.recordId] then
        log('Daedra: Levelled: Processing')
    elseif daedra.type.record(daedra.recordId).isRespawning then
        log('Daedra: Respawning: Processing')
    else
        if storage.playerSection('SettingsGroup_AR_DUBE')
            :get('RemoveEquipmentFromUniqueAndRareDaedraSetting')
        then
            log('Daedra: Unique or Rare: Ignoring (Remove Equipment from Unique and Rare Daedra = Yes)')
        else
            log('Daedra: Unique or Rare: No actions (Remove Equipment from Unique and Rare Daedra = No)')
            return
        end
    end

    for ind, item in ipairs(daedra.type.inventory(daedra):getAll()) do
        if types.Armor.objectIsInstance(item)
            or types.Weapon.objectIsInstance(item)
        then
            log('Inventory: ' .. item.recordId)
            processEquipment(item)
        end
    end
end

local function processDiedCreature(creature)
    log('Died Creature: ' .. creature.recordId)

    if not storage.playerSection('SettingsGroup_AR_DUBE'):get('EnableSetting') then
        log('Mod Disabled: No actions')
        return
    end

    if creature.type.record(creature.recordId).type == types.Creature.TYPE.Daedra then
        processDaedra(creature)
    else
        log('Not Daedra: No actions')
        return
    end
end

return {
    engineHandlers = {
        onInit = initData,
        onLoad = initData
    },
    eventHandlers = {
        processDiedCreature = processDiedCreature
    }
}
