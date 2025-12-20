local storage = require("openmw.storage")
local types = require("openmw.types")
local core = require("openmw.core")
local I = require("openmw.interfaces")

require("scripts.BruteForce.utils.consts")
local omw_utils = require("scripts.BruteForce.utils.openmw_utils")

local sectionDebug = storage.globalSection("SettingsBruteForce_debug")
local l10n = core.l10n("BruteForce")

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
        data.sender:sendEvent("lockWasJammed", { o = data.o })
        omw_utils.displayMessage(data.sender, l10n("lock_was_jammed"))
    else
        local o = data.o

        if types.Container.objectIsInstance(o) then
            local inv = o.type.inventory(o)
            -- populate container's leveled list if needed
            if not inv:isResolved() then
                inv:resolve()
            end
        end

        data.sender:sendEvent("lockWasntJammed", { o = o })
    end
end

local function setJammedLock(data)
    JammedLocks[data.id] = data.val
end

local function addBounty(data)
    omw_utils.addBounty(data.player, data.bounty)
end

I.Activation.addHandlerForType(types.Door, lockableOpen)
I.Activation.addHandlerForType(types.Container, lockableOpen)

return {
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
    },
    eventHandlers = {
        checkJammedLock = checkJammedLock,
        setJammedLock = setJammedLock,
        addBounty = addBounty,
    },
}
