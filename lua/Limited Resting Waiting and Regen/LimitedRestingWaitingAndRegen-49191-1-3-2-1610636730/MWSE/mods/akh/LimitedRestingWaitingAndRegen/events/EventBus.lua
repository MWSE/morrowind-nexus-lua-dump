local constants = require('akh.LimitedRestingWaitingAndRegen.Constants')
local modInfo = require('akh.LimitedRestingWaitingAndRegen.ModInfo')

local function handleOnce(eventName, callback)
    local function handler()
        event.unregister(eventName, handler)
        callback()
    end
    event.register(eventName, handler)
end

event.register("uiEvent", function(e)

    if e.block.id == constants.ui.ID_BUTTON_WAIT then
        if e.property == constants.ui.ID_PROPERTY_MOUSECLICK then
            event.trigger(constants.event.PLAYER_WAIT)
            handleOnce("menuExit", function()
                event.trigger(constants.event.PLAYER_WAITED)
            end)
        end
    end

    if e.block.id == constants.ui.ID_BUTTON_REST then
        if e.property == constants.ui.ID_PROPERTY_MOUSECLICK then
            event.trigger(constants.event.PLAYER_REST)
            handleOnce("menuExit", function()
                event.trigger(constants.event.PLAYER_RESTED)
            end)
        end
    end

    if e.block.id == constants.ui.ID_BUTTON_REST_UNTIL_HEALED then
        if e.property == constants.ui.ID_PROPERTY_MOUSECLICK then
            event.trigger(constants.event.PLAYER_REST)
            handleOnce("menuExit", function()
                event.trigger(constants.event.PLAYER_RESTED)
            end)
        end
    end

    if e.block.id == constants.ui.ID_MENU_SERVICE_TRAVEL then
        
        local actor = tes3ui.getServiceActor()
        local npcClass = actor.reference.object.class

        local eventData = {
            npcClass = npcClass.id
        }

        if e.property == constants.ui.ID_PROPERTY_MOUSECLICK then
            event.trigger(constants.event.PLAYER_TRAVEL, eventData, { filter = eventData.npcClass })
            handleOnce("menuExit", function()
                event.trigger(constants.event.PLAYER_TRAVELED, eventData, { filter = eventData.npcClass })
            end)
        end
    end

end)

print("[" .. modInfo.modName .. " " .. modInfo.modVersion .. "] Event Bus Loaded")