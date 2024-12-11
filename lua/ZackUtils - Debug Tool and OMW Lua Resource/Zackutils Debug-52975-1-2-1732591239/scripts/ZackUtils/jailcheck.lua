local core = require("openmw.core")
local jailTime
return
{
    eventHandlers = {
        UiModeChanged = function(data)
            if data.newMode == "Jail" then
                jailTime = core.getGameTime()
            elseif not data.newMode and jailTime then
                print("Jail start", jailTime)
                print("Jail end", core.getGameTime())
                --1000 bounty:
                -- Jail start    119621.22802734
                --Jail end    206021.22802734
            end
        end,
    }
}
