local constants = require('akh.LimitedRestingWaitingAndRegen.Constants')
local config = require("akh.LimitedRestingWaitingAndRegen.Config")
local modInfo = require('akh.LimitedRestingWaitingAndRegen.ModInfo')

local function hideUntilHealed(e)
    local restUntilHealedButton = e.element:findChild(tes3ui.registerID('MenuRestWait_untilhealed_button'))
    if restUntilHealedButton ~= nil then
        restUntilHealedButton.visible = false
    end
end

local function replaceUntilHealedWithUntilHour(e, text, targetHour)

    local restUntilHealedButton = e.element:findChild(tes3ui.registerID('MenuRestWait_untilhealed_button'))
    local restButton = e.element:findChild(tes3ui.registerID('MenuRestWait_rest_button'))

    if restUntilHealedButton ~= nil and restButton ~= nil and restButton.visible == true then
        restUntilHealedButton.visible = true
        restUntilHealedButton.text = text

        local scrollBar = e.element:findChild(tes3ui.registerID('MenuRestWait_scrollbar'))
        restUntilHealedButton:register(
            'mouseClick',
            function()

                local gameHour = tes3.getGlobal('GameHour')
                local hoursToRest
                if (gameHour >= targetHour) then
                    hoursToRest = 24 - gameHour + targetHour
                else
                    hoursToRest = targetHour - gameHour
                end

                scrollBar.widget.current = hoursToRest
                scrollBar:triggerEvent('PartScrollBar_changed')
                restButton:triggerEvent('mouseClick')
            end
        )
    end

end

local function onMenuRestWaitActivated(e)

    if config.contextualRestButtonPreset == constants.config.contextualRestButtonPreset.VANILLA and config.healthRegenPreset ~= constants.config.healthRegenPreset.VANILLA then
        hideUntilHealed(e)

    elseif config.contextualRestButtonPreset == constants.config.contextualRestButtonPreset.UNTIL_MORNING then
        replaceUntilHealedWithUntilHour(e, config.untilMorningButtonText, config.morningHour)

    elseif config.contextualRestButtonPreset == constants.config.contextualRestButtonPreset.UNTIL_MORNING_EVENING then

        local gameHour = tes3.getGlobal('GameHour')
        if gameHour >= config.morningHour and gameHour < config.eveningHour then
            replaceUntilHealedWithUntilHour(e, config.untilEveningButtonText, config.eveningHour)
        else
            replaceUntilHealedWithUntilHour(e, config.untilMorningButtonText, config.morningHour)
        end
        
    end
    
end

event.register('uiActivated', onMenuRestWaitActivated, {filter = 'MenuRestWait'})

print("[" .. modInfo.modName .. " " .. modInfo.modVersion .. "] UI Module Loaded")