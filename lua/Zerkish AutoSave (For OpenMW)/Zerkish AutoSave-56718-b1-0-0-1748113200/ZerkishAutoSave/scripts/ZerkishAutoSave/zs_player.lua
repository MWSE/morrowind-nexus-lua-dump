-- ZerkishAutoSave - zs_player.lua
-- Author: Zerkish (2025)

local async = require('openmw.async')
local Actor = require('openmw.types').Actor
local core = require('openmw.core')
local self = require('openmw.self')
local Player = require('openmw.types').Player
local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')

local SEC_PER_MIN = 60
local SEC_PER_HR = SEC_PER_MIN * 60
local SEC_PER_DAY = SEC_PER_HR * 24

local ZSAVE_RETRY_SECONDS = 20

local ZSAVE_VERSION = 'a0.2'

local sAutoSaveEnable = true
local sAutoSaveCount = 2
local sAutoSaveInterval = 5.0
local sAutoSaveCellChange = true
local sAutoSaveCellDelay = 20

local ZSaveData = {
    saves = {},
    autosaveTimer = sAutoSaveInterval * 60.0,
    nextRequestId = 1,
    pending = nil,
}

local lastTime = nil
local lastCell = nil
local cellSaveTimer = 0.0

local function loadData_V1(load)
    assert(load.version == 1)
    ZSaveData = load.saveData
end

local function saveData_V1()
    local data = {
        version = 1,
        saveData = ZSaveData,
    }
    return data
end

local function getSaveStr(save)
    return string.format("(slot: %d, timestamp: %d)", save.slot, save.timestamp)
end

local function updateMaxSaveSlots()
    local new = {}
    for i=1,#ZSaveData.saves do
        if ZSaveData.saves[i].slot <= sAutoSaveCount then
            table.insert(new, ZSaveData.saves[i])
        end
    end
    ZSaveData.saves = new
    
    if ZSaveData.pending and ZSaveData.pending.slot > sAutoSaveCount then
        ZSaveData.pending = nil
    end
end

local function settingsListener(section, key)
    local sectionData = storage.playerSection(section)

    if not sectionData then return end

    if section == "Settings_ZSave_AutoSave" then
        if key == nil or key == "autosave_enable" then
            sAutoSaveEnable = sectionData:get('autosave_enable')
            print(string.format('ZSave.sAutoSaveEnable = %s', sAutoSaveEnable and 'true' or 'false'))
            
            I.Settings.updateRendererArgument("Settings_ZSave_AutoSave", "autosave_interval", {
                disabled = not sAutoSaveEnable
            })
            -- I.Settings.updateRendererArgument("Settings_ZSave_AutoSave", "autosave_count", {
            --     disabled = not sAutoSaveEnable
            -- })
        end
        if key == nil or key == "autosave_interval" then
            sAutoSaveInterval = sectionData:get('autosave_interval')
            print(string.format('ZSave.sAutoSaveInterval = %.2f', sAutoSaveInterval))
            ZSaveData.autosaveTimer = math.min(ZSaveData.autosaveTimer, sAutoSaveInterval * 60)
        end
        if key == nil or key == "autosave_count" then
            sAutoSaveCount = sectionData:get('autosave_count')
            print(string.format('ZSave.sAutoSaveCount = %d', sAutoSaveCount))
            updateMaxSaveSlots()
        end
        if key == nil or key == 'autosave_cell_change' then
            sAutoSaveCellChange = sectionData:get('autosave_cell_change')
            print(string.format('ZSave.sAutoSaveCellChange = %s', tostring(sAutoSaveCellChange)))
            I.Settings.updateRendererArgument("Settings_ZSave_AutoSave", "autosave_cell_delay", {
                disabled = not sAutoSaveCellChange
            })            
        end
        if key == nil or key == 'autosave_cell_delay' then
            sAutoSaveCellDelay = sectionData:get('autosave_cell_delay')
            print(string.format('ZSave.sAutoSaveCellDelay = %s', tostring(sAutoSaveCellDelay)))
            cellSaveTimer = math.min(cellSaveTimer, sAutoSaveCellDelay)
        end
    end
end

local function onInit()
    print('ZSave onInit')
end

local function onActive()
    print('ZSave onActive')
    lastTime = core.getRealTime()

    settingsListener('Settings_ZSave_AutoSave', nil)

    local autosaveSettings = storage.playerSection('Settings_ZSave_AutoSave')
    assert(autosaveSettings)
    autosaveSettings:subscribe(async:callback(settingsListener))
end

local function onLoad(data)
    print('ZSave onLoad', data)
    if not data then return end

    if data.version == 1 then
        loadData_V1(data)
    end

    for i,v in ipairs(ZSaveData.saves) do
        print(string.format("ZSave onLoad - AutoSave (%d) %s", i, getSaveStr(ZSaveData.saves[i])))
    end

    -- Due to the nature of a save mod, we won't have confirmation for the last save we did, so we need to request it on load.
    if ZSaveData.pending then
        print(string.format("ZSave onLoad found pending save, request confirmation: %s", getSaveStr(ZSaveData.pending)))
        Player.sendMenuEvent(self, 'ZSave_onSaveConfirmEvent', {
            save = ZSaveData.pending,
        })
    end
end

local function onSave()
    print('ZSave onSave')
    return saveData_V1()
end

local function getOldestSaveIndex()
    local low = nil
    for i=1,#ZSaveData.saves do
        if low == nil or ZSaveData.saves[i].timestamp < ZSaveData.saves[low].timestamp then
            low = i
        end
    end

    return low
end

local function makeSaveGameData(slot, requestId, location, time)
    local data = {}

    --data.requestId = requestId
    data.slot = slot
    -- timestamp for the request itself, for internal tracking.    
    data.timestamp = os.time()
    data.location = location
    data.time = time

    return data
end

local function onReceiveSaveResult(result)
    print('ZSPlayer ZSave_onPlayerSaveEvent')
    if not ZSaveData.pending then 
        print('ZSave onReceiveSaveResult - No Pending Save!')
        return
    end

    print(string.format("\tresult: %s", result.result and 'true' or 'false'))
    --print(string.format("\tsave.requestId: %d", result.save.requestId))
    print(string.format("\tsave.slot: %d", result.save.slot))
    print(string.format("\tsave.timestamp: %d", result.save.timestamp))

    if result.save and result.save.slot > sAutoSaveCount then
        print("ZSave Received Confirmation for unused SaveSlot", result.save.slot)
        ZSaveData.pending = nil
        return
    end

    if result.result then
        --assert(ZSaveData.pending.requestId == result.save.requestId)
        assert(ZSaveData.pending.timestamp == result.save.timestamp)

        if ZSaveData.pending.slot > #ZSaveData.saves then
            assert(#ZSaveData.saves == ZSaveData.pending.slot - 1)
            table.insert(ZSaveData.saves, ZSaveData.pending)
        else
            ZSaveData.saves[ZSaveData.pending.slot] = ZSaveData.pending
        end

        ZSaveData.pending = nil
        ZSaveData.autosaveTimer = sAutoSaveInterval * 60
    else
        print(string.format('ZSave Failed - Retrying in %d seconds.', ZSAVE_RETRY_SECONDS))
        ZSaveData.autosaveTimer = ZSAVE_RETRY_SECONDS
        ZSaveData.pending = nil
    end
end

--local auxTime = require('openmw_aux.time')

local function capitalize(str)
    local r = str:gsub('^%l', function(c) return c:upper() end)
    r = r:gsub(' %l', function(c) return c:upper() end)
    return r
end

local function requestSave()
    print('ZSave player.requestSave, #ZSaveData.saves', #ZSaveData.saves)

    local overwrite = nil
    local slot = nil
    if #ZSaveData.saves < sAutoSaveCount then
        slot = #ZSaveData.saves + 1
    else
        overwrite = getOldestSaveIndex()
        slot = overwrite
    end

    local location = ""

    if self.object.cell then
        location = self.object.cell.name
        if location == nil or #location == 0 and self.object.cell.region then
            location = capitalize(self.object.cell.region)
        end
    end

    --local testTime1 = 1 * SEC_PER_DAY + 17 * SEC_PER_HR + 5 * SEC_PER_MIN + 49

    local timeElapsed = core.getSimulationTime() / core.getSimulationTimeScale()

    local days = math.floor(timeElapsed / SEC_PER_DAY)
    local hrSeconds = timeElapsed % SEC_PER_DAY
    local hours = math.floor(hrSeconds / SEC_PER_HR)
    local minSeconds = timeElapsed % SEC_PER_HR
    local minutes = math.floor(minSeconds / SEC_PER_MIN)

    local time = ""
    if days > 0 then
        time = string.format("%dd", days)
    end
    if hours > 0 or days > 0 then
        time = string.format("%s%dh", time, hours)
    end
    time = string.format("%s%02dm", time, minutes)

    ZSaveData.pending = makeSaveGameData(slot, ZSaveData.nextRequestId, location, time)
    --ZSaveData.nextRequestId = ZSaveData.nextRequestId + 1

    local request = {
        overwrite = overwrite and ZSaveData.saves[overwrite] or nil,
        save = ZSaveData.pending,
    }

    print('request.overwrite', request.overwrite)
    if request.overwrite then
        --print(string.format("\tid: %d", request.overwrite.requestId))
        print(string.format("\tslot: %d", request.overwrite.slot))
        print(string.format("\ttimestamp: %d", request.overwrite.timestamp))
    end

    print('request.save', request.save)
    assert(request.save)
    --print(string.format("\tid: %d", request.save.requestId))
    print(string.format("\tslot: %d", request.save.slot))
    print(string.format("\ttimestamp: %d", request.save.timestamp))

    Player.sendMenuEvent(self, 'ZSave_onSaveRequestEvent', request)
end

local function setAutoSaveEnable(value)
    local section = storage.playerSection('Settings_ZSave_AutoSave')
    if section then
        section:set('autosave_enable', value)
    end
end

local function isSavePending()
    return ZSaveData.pending ~= nil
end

local function canSaveGame()
    local saveBlockedByUI = I.UI.getMode() ~= nil
    local saveBlockedByCharGen = not Player.isCharGenFinished(self.object)
    return not (isSavePending() or saveBlockedByUI or saveBlockedByCharGen)
end

local function checkAutoSave()
    if not sAutoSaveEnable then return end

    if (ZSaveData.autosaveTimer <= 0.0) then
        requestSave()
    end
end

local function checkCellSave()
    if not sAutoSaveCellChange then
        return
    end

    if not lastCell then
        lastCell = self.object.cell
        return
    end

    local newCell = self.object.cell
    -- print("ZSave checkCellChange - Current", newCell.name)

    if newCell and (newCell.id ~= lastCell.id) then
        -- Don't save when moving between different exterior cells.
        local ignore = newCell.isExterior and lastCell.isExterior

        -- print(string.format("ZSave Last Cell (id: %s, name: %s, region: %s, exterior: %s)", lastCell.id, lastCell.name, lastCell.region, tostring(lastCell.isExterior)))
        -- print(string.format("ZSave New Cell (id: %s, name: %s, region: %s, exterior: %s)", newCell.id, newCell.name, newCell.region, tostring(newCell.isExterior)))
        
        if (not ignore) and (cellSaveTimer <= 0.0) then
            requestSave()
            cellSaveTimer = sAutoSaveCellDelay
        end

        lastCell = newCell
    end
end

return {
    engineHandlers = {
        onInit = onInit,
        onLoad = onLoad,
        onSave = onSave,
        onActive = onActive,

        onUpdate = function(dt)
            local realTime = core.getRealTime()
            local delta = realTime - lastTime
            lastTime = realTime

            ZSaveData.autosaveTimer = ZSaveData.autosaveTimer - delta
            cellSaveTimer = cellSaveTimer - delta

            if canSaveGame() then
                checkCellSave()
                checkAutoSave()
            end
        end,

        onKeyPress = function(key)

            -- if key.symbol == 'c' then
            --     local sTable = storage.allPlayerSections()
            --     for k,v in pairs(sTable) do
            --         print('sTable[' .. tostring(k) .. '] = ' .. tostring(v))
            --     end
            -- end

            -- -- DEBUG
            -- if key.symbol == 'x' then

            --     if not isSavePending() then
            --         requestSave()
            --     end
            -- end

            -- if key.symbol == 'z' then
            --     setAutoSaveEnable(not sAutoSaveEnable)
            -- end
        end,
    },

    eventHandlers = {
        ZSave_onSaveResultEvent = onReceiveSaveResult,
    }
}