local sneak = require("celediel.MoreAttentiveGuards.sneak")
local combat = require("celediel.MoreAttentiveGuards.combat")
local common = require("celediel.MoreAttentiveGuards.common")

-- in order for this to work, functions in returned table must follow naming pattern: onEventName
local function registerFunctionEvents(t)
    for name, func in pairs(t) do
        if type(func) == "function" then event.register(name:gsub("on(%u)", string.lower), func) end
    end
end

local function onInitialized()
    registerFunctionEvents(sneak)
    registerFunctionEvents(combat)
    common.log("Successfully initialized")
end

event.register("initialized", onInitialized)
event.register("modConfigReady", function() mwse.mcm.register(require("celediel.MoreAttentiveGuards.mcm")) end)
