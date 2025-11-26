local aux_util = require("openmw_aux.util")
local storage = require("openmw.storage")
local nearby = require("openmw.nearby")
local self = require("openmw.self")
local core = require("openmw.core")

require("scripts.DeadMerTellNoTales.utils.tables")

local sectionRecording = storage.globalSection("SettingsDeadMerTellNoTales_recording")
local sectionObjTypes = storage.globalSection("SettingsDeadMerTellNoTales_objectTypes")
local sectionDebug = storage.globalSection("SettingsDeadMerTellNoTales_debug")

local function ownershipFilter(object)
    return object.owner.recordId == self.recordId
end

local function removeOwnership()
    local disownItems      = sectionObjTypes:get("disownItems")
    local disownContainers = sectionObjTypes:get("disownContainers")
    local disownActivators = sectionObjTypes:get("disownActivators")
    local disownDoors      = sectionObjTypes:get("disownDoors")
    
    local objects = {}
    for _, entry in ipairs {
        disownItems      and aux_util.mapFilter(nearby.items,      ownershipFilter),
        disownContainers and aux_util.mapFilter(nearby.containers, ownershipFilter),
        disownActivators and aux_util.mapFilter(nearby.activators, ownershipFilter),
        disownDoors      and aux_util.mapFilter(nearby.doors,      ownershipFilter),
    } do
        if entry then
            for _, object in ipairs(entry) do
                objects[#objects+1] = object
            end
        end
    end

    core.sendGlobalEvent("disown", objects)
    core.sendGlobalEvent("recordDead", self.recordId)
    
    if sectionDebug:get("debugEnabled") then
        print(self.recordId .. " is recorded as dead")
    end
end

local function checkIfEnabled()
    if self.enabled then return end
    if not sectionRecording:get("recordDisabled") then return end
    removeOwnership()
end

local function onDeath()
    if not sectionRecording:get("recordKilled") then return end
    removeOwnership()
end

return {
    engineHandlers = {
        onInactive = checkIfEnabled
    },
    eventHandlers = {
        Died = onDeath
    }
}
