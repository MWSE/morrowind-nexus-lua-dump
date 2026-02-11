local storage = require("openmw.storage")
local types = require("openmw.types")
local I = require("openmw.interfaces")

require("scripts.BruteForce.utils.consts")
require("scripts.BruteForce.utils.openmw_utils")
require("scripts.BruteForce.logic.lockBehavior")

local sectionDebug = storage.globalSection("SettingsBruteForce_debug")

local function lockableOpen(o, actor)
    JammedLocks[o.id] = nil
end

local function onLoad(savedData)
    JammedLocks = savedData
end

local function onSave()
    return JammedLocks
end

local function checkJammedLock(data)
    if JammedLocks[data.o.id] and not sectionDebug:get("ignoreBentLocks") then
        LockWasJammed(data.o, data.sender)
    else
        LockWasntJammed(data.o, data.sender, JammedLocks)
    end
end

local function addBounty(data)
    AddBounty(data.player, data.bounty)
end
local function triggerTrap(data)
    TriggerTrap(data.o, data.player)
end

I.Activation.addHandlerForType(types.Door, lockableOpen)
I.Activation.addHandlerForType(types.Container, lockableOpen)

return {
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
    },
    eventHandlers = {
        CheckJammedLock = checkJammedLock,
        AddBounty = addBounty,
        TriggerTrap = triggerTrap,
    },
}
