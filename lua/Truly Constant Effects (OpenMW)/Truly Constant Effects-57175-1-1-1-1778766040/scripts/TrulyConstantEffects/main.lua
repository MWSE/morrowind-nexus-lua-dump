local storage = require("openmw.storage")

local PlayerState = require("scripts.TrulyConstantEffects.playerState")

local settings = storage.playerSection("SettingsTrulyConstantEffects")
local checkEvery = math.max(0, settings:get('cooldown'))
local updateTime = math.random() * checkEvery
local playerState = PlayerState:new(settings)
local isSecondFrame = false

return {
    engineHandlers = {
        onUpdate = function(dt)
            -- cooldown
            updateTime = updateTime + dt

            if updateTime < checkEvery then return end

            if checkEvery == 0 then
                updateTime = 0
            else
                while updateTime > checkEvery do
                    updateTime = updateTime - checkEvery
                end
            end

            -- actual logic
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
