---This file contains static properties that cannot be changed.
---@class GuarWhisperer.Config.Properties
local Properties = {
    WAITING_IDLE_CHANCES = {
        { group = "idle3", maxChance =  25 },  --sit
        { group = "idle4", maxChance = 50 },  --eat
        { group = "idle5", maxChance = 100 },  --look
     }
}

return Properties