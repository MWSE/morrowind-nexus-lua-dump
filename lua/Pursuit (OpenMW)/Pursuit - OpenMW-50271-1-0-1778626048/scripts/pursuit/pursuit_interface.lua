require "scripts.pursuit.defs"
local types = require("openmw.types")
local util = require("openmw.util")
local time = require("openmw_aux.time")
local I = require("openmw.interfaces")

local handlers = require "scripts.pursuit.pursuit_handlers"
local pursuit = require "scripts.pursuit.pursuit"
local blacklist = require "scripts.pursuit.blacklist"
local settings = require "scripts.pursuit.settings"

blacklist:updateBlacklist()
settings:updateSettings(handlers:updateHandlers())

getGlobalStore("@Pursuit@"):setLifeTime(2) -- storage.LIFE_TIME.Temporary == 2

-- the beginning of pursuit
-- FUTURE: support 'portal' like doors, scripted doors, queued activation, etc.
I.Activation.addHandlerForType(types.Door, function(door, activator)
    if not door.type.isTeleport(door) then return end
    if activator.type == types.Player then
        getGlobalStore("@Pursuit@"):set("updatePath") -- update paths of pursuers
        -- player->onTeleported
    else
        for _, obj in pairs(door.cell:getAll( --[[types.Actor]])) do
            if obj.type.baseType == types.Actor then
                obj:sendEvent("Pursuit_pursueTarget", { target = activator })
            end
        end
    end
end)

time.runRepeatedly(function()
    getGlobalStore("@Pursuit@"):set("updateState") -- update state of pursuers
end, time.day, { type = time.GameTime })

return {
    interfaceName = "Pursuit",
    interface = setmetatable({
        version = require("scripts.pursuit.modInfo").MOD_VERSION,
        help = require("scripts.pursuit.modInfo").HELP,
        info = tostring(require("scripts.pursuit.modInfo")),
    }, {
        __index = {
            isActive = function()
                return getGlobalStore("Settings!_Pursuit_!"):get("isActive")
            end,
            getBlacklist = function()
                return util.makeReadOnly(blacklist:get())
            end,
            addBlacklist = function(recordId)
                return blacklist:add(recordId)
            end,
            removeBlacklist = function(recordId)
                return blacklist:remove(recordId)
            end,
            getHandlers = function()
                return handlers:get()
            end,
            addHandler = function(fn, name)
                handlers:add(fn, name)
            end,
            removeHandler = function(name)
                handlers:remove(name)
            end
        }

    }),
    eventHandlers = {
        Pursuit_updatePursuer = pursuit.updatePursuer,
        Pursuit_pursueTarget = pursuit.pursueTarget,
        Pursuit_safeTeleport = safeTeleport,
    }
}
