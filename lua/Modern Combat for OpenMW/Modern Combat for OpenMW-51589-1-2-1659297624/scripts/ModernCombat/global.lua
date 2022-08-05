local types = require("openmw.types")
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local MOD_NAME = "ModernCombat"
local MOD_SETTINGS = MOD_NAME .. "Settings__"

I.Settings.registerGroup {
    key = MOD_SETTINGS,
    page = MOD_NAME,
    l10n = MOD_NAME,

    name = "Options",
    permanentStorage = false,

    settings = {{
        key = "Disabled",
        name = "Disabled",
        default = false,
        renderer = "checkbox"
    }, {
        key = "Dodge",
        name = "Side dodge",
        default = false,
        renderer = "checkbox"
    }, {
        key = "Backward",
        name = "Backward drain",
        default = true,
        renderer = "checkbox"
    }}
}

local values = storage.globalSection(MOD_NAME)

local function onActorActive(actor)
    if actor and (actor.type == types.NPC or actor.type == types.Creature) then
        actor:addScript("scripts/ModernCombat/npc.lua")
    end
end

return {
    eventHandlers = {
        ActorInactive = function(data)
            local actor = unpack(data)
            actor:removeScript("scripts/ModernCombat/npc.lua")
        end,
        PlayerStats = function(data)
            local stats = unpack(data)
            values:set("PlayerFatigue", stats.fatigue)
        end
    },
    engineHandlers = {
        onActorActive = onActorActive
    }
}
