local aux_util = require("openmw_aux.util")
local storage = require("openmw.storage")
local nearby = require("openmw.nearby")
local self = require("openmw.self")
local core = require("openmw.core")

require("scripts.DeadMerTellNoTales.utils.tables")
require("scripts.DeadMerTellNoTales.utils.consts")

local sectionRecording = storage.globalSection("SettingsDeadMerTellNoTales_recording")
local sectionObjTypes = storage.globalSection("SettingsDeadMerTellNoTales_objectTypes")
local sectionDebug = storage.globalSection("SettingsDeadMerTellNoTales_debug")

local function selfIsOwner(object)
    return object.owner.recordId == self.recordId
end

local function isGuard(actor)
    return string.find(actor.recordId, "guard")
        or string.find(actor.recordId, "ordinator")
        or actor.type.records[actor.recordId].class == "guard"
        or actor.type.records[actor.recordId].class == "ordinator"
end

local function cellIgnoredDueToQuest(actor)
    local questsByCell = IgnoredCellsWhileQuestActive[actor.cell.id]
    if not questsByCell then return false end

    for _, blacklistedQuest in ipairs(questsByCell) do
        for _, player in ipairs(nearby.players) do
            local quests = player.type.quests(player)
            ---@diagnostic disable-next-line: undefined-field
            if quests[blacklistedQuest.id].stage == blacklistedQuest.stage then
                return true
            end
        end
    end

    return false
end

local function removeOwnership()
    -- guards are ignored completely
    if isGuard(self) then return end

    local disownItems      = sectionObjTypes:get("disownItems")
    local disownContainers = sectionObjTypes:get("disownContainers")
    local disownActivators = sectionObjTypes:get("disownActivators")
    local disownDoors      = sectionObjTypes:get("disownDoors")

    local objects          = {}
    for _, entry in ipairs {
        disownItems and aux_util.mapFilter(nearby.items, selfIsOwner),
        disownContainers and aux_util.mapFilter(nearby.containers, selfIsOwner),
        disownActivators and aux_util.mapFilter(nearby.activators, selfIsOwner),
        disownDoors and aux_util.mapFilter(nearby.doors, selfIsOwner),
    } do
        if entry then
            for _, object in ipairs(entry) do
                objects[#objects + 1] = object
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
    if self.enabled
        or cellIgnoredDueToQuest(self)
        or not sectionRecording:get("recordDisabled")
    then
        return
    end

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
