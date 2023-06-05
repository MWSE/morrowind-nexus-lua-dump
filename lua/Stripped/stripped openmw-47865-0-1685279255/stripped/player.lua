local ui = require "openmw.ui"
local self = require "openmw.self"
local nearby = require "openmw.nearby"
local types = require "openmw.types"
local getHealth = types.Actor.stats.dynamic.health
local ISENABLED = true
return {
    engineHandlers = {
        onConsoleCommand = function(mode, command, selectedobject)
            if command:lower() == "luastripped" then
                ISENABLED = not ISENABLED
                print(string.format("STRIPPED is %s", ISENABLED and "ENABLED" or "DISABLED"))
            end
            if ISENABLED and ui.showMessage then
                ui.showMessage("STRIPPED IS ENABLED")
            else
                ui.showMessage("STRIPPED IS DISABLED")
            end
        end,
        onUpdate = function(dt)
            if not ISENABLED then
                return
            end
            for i, target in pairs(nearby.actors) do
                local dist = (target.position - self.position):length()
                if target ~= self.object and types.NPC.objectIsInstance(target) and getHealth(target).current > 0 then
                    if dist < 150 then
                        target:sendEvent("STRIPPED", true)
                    else
                        target:sendEvent("STRIPPED", false)
                    end
                end
            end
        end
    },
}
