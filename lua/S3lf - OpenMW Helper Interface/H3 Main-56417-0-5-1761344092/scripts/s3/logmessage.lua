local types = require('openmw.types')
local Player = types.Player

---@type ScriptContext
local ScriptContext = require('scripts.s3.scriptContext')
local CurrentContext = ScriptContext.get()

local World, Self, ui, nearby

if CurrentContext == ScriptContext.Types.Global then
    World = require('openmw.world')
elseif CurrentContext ~= ScriptContext.Types.Menu then
    Self = require('openmw.self')

    if Player.objectIsInstance(Self) then
        ui = require('openmw.ui')
    else
        nearby = require('openmw.nearby')
    end
end

--- Prints a message to the console, directly using the console OR to nearby players if the attached object isn't a player
---@param messageString string The message to print to the console
local function LogMessage(messageString)
    if CurrentContext == ScriptContext.Types.Global then
        assert(World, "World is not available")

        for _, player in pairs(World.players) do
            player:sendEvent('S3LFDisplay', messageString)
        end
    else
        if CurrentContext == ScriptContext.Types.Player then
            ui.printToConsole(messageString, ui.CONSOLE_COLOR.Success)
        elseif CurrentContext == ScriptContext.Types.Local then
            for _, player in pairs(nearby.players) do
                player:sendEvent('S3LFDisplay', messageString)
            end
        end
    end
end

return LogMessage
