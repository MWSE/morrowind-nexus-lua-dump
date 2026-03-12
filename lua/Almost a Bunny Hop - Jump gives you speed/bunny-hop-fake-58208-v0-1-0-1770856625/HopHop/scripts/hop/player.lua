local ui = require('openmw.ui')
local input = require('openmw.input') 
local types = require('openmw.types')
local self = require('openmw.self')

-- Config
local TIME_LIMIT = 2.0        -- If you dont jump in this time limit all combo is lost
local MIN_COOLDOWN = 0.5      -- Min time (less than this we ignore so theres no spam on jumps)
local SPEED_INCREMENT = 150   
local MAX_BONUS = 1000        

-- States
local timeSinceLastInput = 0
local currentSpeedBonus = 0

-- So the bonus isnt eternal
local function removeBonus(amount)
    if amount and amount > 0 then
        local speedStat = types.Actor.stats.attributes.speed(self)
        speedStat.base = speedStat.base - amount
    end
end

-- Reset the combo
local function resetCombo()
    if currentSpeedBonus > 0 then
        removeBonus(currentSpeedBonus)
        currentSpeedBonus = 0
    end
end

local function onJumpInput()
    if self.type == types.Player then
        
        -- Make sure theres no spam 
        if currentSpeedBonus > 0 and timeSinceLastInput < MIN_COOLDOWN then
            return 
        end

        local speedStat = types.Actor.stats.attributes.speed(self)
        
        -- Speed increase logic
        if timeSinceLastInput <= TIME_LIMIT or currentSpeedBonus == 0 then
            
            
            if currentSpeedBonus < MAX_BONUS then 
                speedStat.base = speedStat.base + SPEED_INCREMENT
                currentSpeedBonus = currentSpeedBonus + SPEED_INCREMENT
                -- ui.showMessage("Combo +" .. tostring(currentSpeedBonus))
            else
                -- ui.showMessage("Speed Máximo")
            end

            -- Timer reset so we can keep stacking
            timeSinceLastInput = 0
            
        else
            -- Remove bonus if the jump delay was too great
            removeBonus(currentSpeedBonus) 
            
            --  New combo start
            currentSpeedBonus = SPEED_INCREMENT
            speedStat.base = speedStat.base + SPEED_INCREMENT
            ui.showMessage("Combo Reiniciado!")
            
            timeSinceLastInput = 0
        end
    end
end

return {
    engineHandlers = {
        onInputAction = function(id)
            if id == input.ACTION.Jump then
                onJumpInput()
            end
        end,

        onUpdate = function(dt)
            timeSinceLastInput = timeSinceLastInput + dt

            -- If enought time has passed and no jump, reset everything
            if timeSinceLastInput > TIME_LIMIT and currentSpeedBonus > 0 then
                resetCombo()
            end
        end,

        onSave = function()
            -- Saving bonus so theres absolutely no way for the bonus to persist between saves
            return { savedBonus = currentSpeedBonus }
        end,

        onLoad = function(data)
            -- Clear on load always so no infinite stacking
            if data and data.savedBonus and data.savedBonus > 0 then
                removeBonus(data.savedBonus)
                currentSpeedBonus = 0
            end
        end,

        onInactive = function()
            resetCombo()
        end
    }
}