require("scripts.TrulyConstantEffects.playerState")

local playerState = PlayerState:new()
local isSecondFrame = false

return {
    engineHandlers = {
        onUpdate = function()
            if not playerState:isUpToDate() and isSecondFrame then
                playerState:updateSpells()
                isSecondFrame = false
            else
                -- i need one additional frame to refresh the state
                -- lmao
                isSecondFrame = true
            end
        end,
    }
}
