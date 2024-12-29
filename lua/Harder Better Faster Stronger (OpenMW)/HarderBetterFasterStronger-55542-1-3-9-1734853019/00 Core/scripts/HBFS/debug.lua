local mSettings = require('scripts.HBFS.settings')
local mTools = require('scripts.HBFS.tools')

local module = {}

local function debugPrint(str)
    if mSettings.globalSection():get("debugMode") then
        print("DEBUG: " .. str)
    end
end
module.print = debugPrint

local function actorId(actor)
    return string.format("<%s (%s)>", mTools.getRecord(actor).id, actor.id)
end
module.actorId = actorId

return module