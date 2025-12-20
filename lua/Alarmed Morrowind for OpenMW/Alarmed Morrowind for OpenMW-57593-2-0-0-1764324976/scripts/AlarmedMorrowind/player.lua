local storage = require('openmw.storage')
local BL      = require('scripts.AlarmedMorrowind.blacklist')

local npcIdBlacklist = {}

local function log(message)
    if storage.playerSection('SettingsGroup_AR_AM'):get('DebugSetting') then
        print(message)
    end
end

local function logIdList(idList)
    if storage.playerSection('SettingsGroup_AR_AM'):get('DebugSetting') then
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

local function initData()
    log('Init Data')

    npcIdBlacklist = convertIdListToLowerCase(BL.npcAnyCaseIdBlacklist)
    log('NPC Id Blacklist:')
    logIdList(npcIdBlacklist)
end

local function getAlarmValueSetting()
    local value = storage.playerSection('SettingsGroup_AR_AM'):get('AlarmValueSetting')
    if value == 'AlarmValueSetting90' then
        return 90
    elseif value == 'AlarmValueSetting100' then
        return 100
    else
        log('Error: Unexpected Alarm Value Setting = ' .. value)
        return 100
    end
end

local function setAlarmConditional(data)
    local message = nil
    local alarm = nil

    if npcIdBlacklist[data.npc.recordId]
        and storage.playerSection('SettingsGroup_AR_AM'):get('UseBlacklistSetting') then
        message = 'Blacklisted: Setting Init Alarm'
        alarm = data.initAlarm
    elseif data.npc.type.record(data.npc.recordId).class == 'slave'
        and not storage.playerSection('SettingsGroup_AR_AM'):get('AlarmedSlavesSetting') then
        message = 'Not Alarmed Slave: Setting Init Alarm'
        alarm = data.initAlarm
    elseif storage.playerSection('SettingsGroup_AR_AM'):get('EnableSetting') then
        local alarmValueSetting = getAlarmValueSetting()
        message = 'Mod Enabled: Raising Alarm to ' .. alarmValueSetting
        alarm = math.max(alarmValueSetting, data.initAlarm)
    else
        message = 'Mod Disabled: Setting Init Alarm'
        alarm = data.initAlarm
    end

    log(data.npc.recordId .. ': ' .. message
        .. ' (Alarm: Init = ' .. data.initAlarm
        .. ' / Before = ' .. data.npc.type.stats.ai.alarm(data.npc).base
        .. ' / After = ' .. alarm .. ')')
    data.npc:sendEvent('setAlarm', alarm)
end

return {
    engineHandlers = {
        onInit = initData,
        onLoad = initData
    },
    eventHandlers = {
        setAlarmConditional = setAlarmConditional
    }
}
