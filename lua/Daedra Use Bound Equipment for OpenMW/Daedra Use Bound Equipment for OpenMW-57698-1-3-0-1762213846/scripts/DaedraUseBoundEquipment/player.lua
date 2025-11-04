local storage = require('openmw.storage')
local types   = require('openmw.types')
local core    = require('openmw.core')
local BL      = require('scripts.DaedraUseBoundEquipment.blacklists')

local function log(str)
    if storage.playerSection('SettingsGroup'):get('DebugSetting') then
        print('DUBE: ' .. str)
    end
end

local function processDiedCreature(creature)
    log('Died a creature: ' .. creature.recordId)
    if not storage.playerSection('SettingsGroup'):get('EnableSetting') then
        log('The mod is disabled: No actions')
        return
    end
    if creature.type.record(creature.recordId).type == types.Creature.TYPE.Daedra then
        log('The creature is a Daedra: Processing it')
        if BL.daedraIdBlackList[creature.recordId] then
            log('The Daedra is blacklisted: No actions')
            return
        else
            log('The Daedra is not blacklisted: Processing its inventory')
        end
    else
        log('The creature is not a Daedra: No actions')
        return
    end
    for ind, item in ipairs(creature.type.inventory(creature):getAll()) do
        if types.Weapon.objectIsInstance(item) then
            log('Found a weapon: ' .. item.recordId)
            if BL.weaponIdBlackList[item.recordId] then
                log('The weapon is blacklisted: Kept')
            else
                log('The weapon is not blacklisted: Removed')
                core.sendGlobalEvent('removeEquipment', item)
            end
        elseif types.Armor.objectIsInstance(item) then
            log('Found an armor piece: ' .. item.recordId)
            if BL.armorIdBlackList[item.recordId] then
                log('The armor piece is blacklisted: Kept')
            else
                log('The armor piece is not blacklisted: Removed')
                core.sendGlobalEvent('removeEquipment', item)
            end
        end
    end
    log('Processing the inventory is finished')
end

return {
    eventHandlers = {
        processDiedCreature = processDiedCreature
    }
}
