-- version: 1.0

require("scripts.TrulyConstantEffects.playerState")

local playerState
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
        onLoad = function()
            playerState = PlayerState:new()
        end
    }
}
