-- ZerkishAutoSave - zs_menu.lua
-- Author: Zerkish (2025)

local core = require('openmw.core')
local menu = require('openmw.menu')

local ZSavePrefix = "ZSave"
local ZSaveMaxWait = 10.0
local ZSaveCheckInterval = 0.5

local pendingSave = nil

local checkTimer = 0.0
local waitTimer = 0.0


local function getSaveSlot(saveRequest)
    return string.format("%s_%d", ZSavePrefix, saveRequest.slot)
end

local function getSaveName(saveRequest)
    local name = string.format("%s%02d", ZSavePrefix, saveRequest.slot)

    if saveRequest.time then
        name = string.format("%s %s", name, saveRequest.time)
    end

    if saveRequest.location and #saveRequest.location > 0 then
        name = string.format("%s %s", name, saveRequest.location)
    end

    return name
end

local function getSaves()
    local dir = menu.getCurrentSaveDir()
    local allSaves = menu.getSaves(dir)

    local saves = {}

    for k, v in pairs(allSaves) do
        
        local b, e = k:find(ZSavePrefix)
        local isZSave = (b == 1)

        if isZSave then
            saves[k] = v
        end
    end

    return saves
end

-- Looks up an existing save from requestId
-- This is used to find save files regardless of the location they were saved in
-- as we may have lost that data by reloading a previous save.
local function findSaveFileBySlot(requestId)
    print('findSaveFileByRequestId', requestId)
    local saves = getSaves()
    local requestStr = string.format("%02d", requestId)

    for k, v in pairs(saves) do
        print(string.format("findSaveFileByRequestId find %s in %s", requestStr, k))
        local b, e = k:find(requestStr)
        if b and e then
            print('findSaveFileByRequestId - Found!')
            return k
        end
    end

    return nil
end

local replaceChars = { 
    ',', ' ', '\'', '%.', '%-', '#', '%(', '%)', '%%', ':',
 }

-- Returns the name of the file of a request like OpenMW would save it.
local function getSaveFilename(saveRequest)
    local name = getSaveName(saveRequest)
    for i=1,#replaceChars do
        name = name:gsub(replaceChars[i], '_')
    end

    return name .. '.omwsave'
end

local function saveExists(filename)
    local saves = getSaves()
    for k, v in pairs(saves) do

        local isMatch = (k == filename)

        print(string.format("ZSave Compare %s == %s -> %s", filename, k, isMatch and 'true' or 'false'))
        if isMatch then
            return true
        end
    end

    return false
end

local function wasSaveSuccessful()
    assert(pendingSave ~= nil)
    local filename = getSaveFilename(pendingSave)
    return saveExists(filename)
end

local function deleteSaveFile(filename)
    print(string.format("ZSave Delete SaveGame: %s", filename))
    -- Wrap this in a pcall so we DON'T fail to save the game because we can't delete the old save.
    local success, err = pcall(menu.deleteGame, menu.getCurrentSaveDir(), filename)
    if not success then
        print(string.format('ZSave Delete SaveGame Failed: %s', tostring(err)))
    end
end

return {
    engineHandlers = {
        onFrame = function(dt)

            -- If we have a pending save
            -- See if it was successfully saved
            -- If not try to save again (with delay)
            if pendingSave then

                checkTimer = checkTimer - dt

                if checkTimer <= 0.0 then
                    checkTimer = ZSaveCheckInterval

                    if wasSaveSuccessful() then
                        core.sendGlobalEvent("ZSave_onSaveResultEvent", {
                            result = true,
                            save = pendingSave,
                        })
                        pendingSave = nil
                        return
                    end
                end

                -- If we have been trying for too long, abandon the save and let the player script decide when to try again.
                waitTimer = waitTimer + dt
                if waitTimer >= ZSaveMaxWait then
                    core.sendGlobalEvent("ZSave_onSaveResultEvent", {
                        result = false,
                        save = pendingSave,
                    })
                    pendingSave = nil
                end
            end
        end,
    },

    eventHandlers = {

        -- This event is received when we are asked to check for the existence of a save.
        ZSave_onSaveConfirmEvent = function(data)
            print("ZSave_onSaveConfirmEvent")
            local filename = getSaveFilename(data.save)
            core.sendGlobalEvent("ZSave_onSaveResultEvent", {
                result = saveExists(filename),
                save = data.save,
            })
        end,

        -- This event is received when a save is to be made.
        ZSave_onSaveRequestEvent = function(data)
            print("ZSave_onSaveRequestEvent")

            if data.overwrite then
                local filename = getSaveFilename(data.overwrite)
                deleteSaveFile(filename)
            end

            -- Delete this save if it already exists
            -- This can happen if the player loads a previous save.
            local oldFilename = findSaveFileBySlot(data.save.slot)
            if oldFilename then
                deleteSaveFile(oldFilename)
            end

            pendingSave = data.save

            local saveName = getSaveName(data.save)
            local saveSlot = getSaveSlot(data.save)

            menu.saveGame(saveName, saveSlot)

            waitTimer = 0.0
            checkTimer = ZSaveCheckInterval
        end,
    }
}