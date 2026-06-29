local core = require('openmw.core')
local I = require("openmw.interfaces")

local mDef = require("scripts.TakeCover.config.definition")

I.Settings.registerPage {
    key = mDef.MOD_NAME,
    l10n = mDef.MOD_NAME,
    name = "name",
    description = "description",
}

local function onActorTargetsChanged(data)
    core.sendGlobalEvent(mDef.events.onActorTargetsChanged, data)
    data.actor:sendEvent(mDef.events.onTargetsChanged, data.targets)
end

return {
    eventHandlers = {
        OMWMusicCombatTargetsChanged = onActorTargetsChanged,
    }
}