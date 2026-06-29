local mDef = require("scripts.TakeCover.config.definition")
local mStore = require('scripts.TakeCover.config.store')
local mHelpers = require('scripts.TakeCover.util.helpers')
local log = require('scripts.TakeCover.util.log')

mStore.registerGroups()

local function onActorTargetsChanged(actor, targets)
    if #targets > 0 then
        if not actor:hasScript(mDef.scripts.actor) then
            log(string.format("%s got the script", mHelpers.objectId(actor)))
            actor:addScript(mDef.scripts.actor, targets)
        end
    else
        if actor:hasScript(mDef.scripts.actor) then
            log(string.format("%s lost the script", mHelpers.objectId(actor)))
            actor:removeScript(mDef.scripts.actor, targets)
        end
    end
end

return {
    eventHandlers = {
        [mDef.events.onActorTargetsChanged] = function(data) onActorTargetsChanged(data.actor, data.targets) end,
    }
}