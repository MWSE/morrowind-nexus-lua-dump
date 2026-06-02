local core = require("openmw.core")
local I = require("openmw.interfaces")
local nearby = require("openmw.nearby")
local self = require("openmw.self")
local ui = require("openmw.ui")
local l10n = core.l10n("pursuit")
local modInfo = require("scripts.pursuit.modInfo")

local API_REVISION = core.API_REVISION
local MIN_API = modInfo.MIN_API

I.Settings.registerPage {
    key = "pursuit",
    l10n = "pursuit",
    name = "settings_modName",
    description = l10n("settings_modDesc"):format(modInfo.MOD_VERSION)
}

------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------

local function checkVersion()
    if API_REVISION < MIN_API then
        ui.showMessage(l10n("minapiwarning"):format(MIN_API))
    end
end

local function debugMessage(debugData)
    local message = tostring(debugData.message)
    if debugData.print ~= false then
        print(message)
    end
    if debugData.printToConsole ~= false then
        ui.printToConsole(message, ui.CONSOLE_COLOR.Info)
    end
    if debugData.showMessage ~= false then
        ui.showMessage(message)
    end
end

-- nearby.actors returns the list of actors in the cell where teleport happens; not the arrival cell
-- send the event to those actors (with pursuer.lua)
local function onTeleported(--[[prevCell, newCell]])
    for _, actor in pairs(nearby.actors) do
        if actor ~= self.object then
            actor:sendEvent("Pursuit_pursueTarget", { target = self })
        end
    end
end

return {
    engineHandlers = {
        onActive = checkVersion,
        onTeleported = onTeleported
    },
    eventHandlers = {
        Pursuit_debugMessage = debugMessage,
    }
}
