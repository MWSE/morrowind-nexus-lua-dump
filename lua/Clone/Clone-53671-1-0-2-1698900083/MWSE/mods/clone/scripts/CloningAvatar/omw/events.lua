local events = require("scripts.CloningAvatar.events")
local types = require("openmw.types")
local world = require("openmw.world")
local I = require("openmw.interfaces")
I.Activation.addHandlerForType(types.Activator, events.onActivate)
I.Activation.addHandlerForType(types.NPC, events.onActivate)
local function onConsoleCommand(command)

    events.onConsoleCommand(command)
end
local function onKeyPress(keyc)
events.onKeyPress(keyc)
end
local function Clone_QU(data)
events.onQuestUpdate(data.questId,data.stage)
end
local function CellChanged(cellName)
local newCell = world.getCellByName(cellName)
if newCell then
    
events.cellChanged(newCell)
end
end
return {
    engineHandlers = {
        onPlayerAdded = events.onInit
    },
    eventHandlers = {
        onConsoleCommand = onConsoleCommand,
        onKeyPress = onKeyPress,
        Clone_QU = Clone_QU,
        CellChanged = CellChanged,
    }
}
