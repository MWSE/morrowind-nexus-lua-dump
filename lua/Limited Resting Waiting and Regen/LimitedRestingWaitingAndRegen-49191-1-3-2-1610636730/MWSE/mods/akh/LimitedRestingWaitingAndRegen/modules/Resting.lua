local constants = require('akh.LimitedRestingWaitingAndRegen.Constants')
local config = require("akh.LimitedRestingWaitingAndRegen.Config")
local modInfo = require('akh.LimitedRestingWaitingAndRegen.ModInfo')
local playerData = require("akh.LimitedRestingWaitingAndRegen.persistence.PlayerData")

local isWaitRestScripted = false
local vanillaAllowRest = true

local function isPlayerInAnInn()

    local cell = tes3.getPlayerCell()
    if cell.isInterior == false then
        return false
    end

    for actorRef in tes3.iterate(cell.actors) do
        -- cell.actors does not provide actual tes3actor refs; has to be fetched with getObject to get complete data i.e. npc class
        local actor = tes3.getObject(actorRef.id)
        if actor.class ~= nil and actor.class.id == constants.npcClass.PUBLICAN then
            return true
        end
    end

    return false

end

local function disallowWaiting(e, text) 

    -- a bit messy find by index since thhis element doesn't have a name to use in tes3ui.registerID
    -- if another mod moodifies structure of this element this will likely fail
    local hoursText = e.element:findChild(tes3ui.registerID("PartNonDragMenu_main")).children[3]
    hoursText.visible = false

    local hoursScrollbar = e.element:findChild(tes3ui.registerID("MenuRestWait_scrollbar"))
    hoursScrollbar.visible = false

    local waitButton = e.element:findChild(tes3ui.registerID("MenuRestWait_wait_button"))
    waitButton.visible = false

    if text ~= nil then
        local labelText = e.element:findChild(tes3ui.registerID("MenuRestWait_label_text"))
        labelText.text = text
        labelText.visible = true
    end

end

local function disallowResting(e, text)

    local restUntilHealedButton = e.element:findChild(tes3ui.registerID('MenuRestWait_untilhealed_button'))
    restUntilHealedButton.visible = false
    local restButton = e.element:findChild(tes3ui.registerID('MenuRestWait_rest_button'))
    restButton.visible = false
    disallowWaiting(e, text)

end

local function handleOnce(eventName, callback)
    local function handler()
        event.unregister(eventName, handler)
        callback()
    end
    event.register(eventName, handler)
end

local function onUiActivated(e)

    local labelText = e.element:findChild(tes3ui.registerID("MenuRestWait_label_text"))
    labelText.visible = false

    if config.restingWaitingAntiSpam == true then

        local restButton = e.element:findChild(tes3ui.registerID("MenuRestWait_rest_button"))
        if restButton ~= nil and restButton.visible == true and tes3.getSimulationTimestamp() - playerData.getLastRestedTimestamp() < 1 then
            disallowResting(e, "I don't feel tired right now.")
            return
        elseif (restButton == nil or restButton.visible == false) and tes3.getSimulationTimestamp() - playerData.getLastWaitedTimestamp() < 1 then
            disallowWaiting(e, "I feel I shouldn't be wasting any more time.")
            return
        end

    end

    -- if it's scripted (e.g. activating a bed) leave the menu as it is
    if isWaitRestScripted == true then
        return
    end

    local waitButton = e.element:findChild(tes3ui.registerID("MenuRestWait_wait_button"))
    if waitButton ~= nil and waitButton.visible == true then

        if config.waitingPreset == constants.config.waitingPreset.VANILLA then
            return
        else
            local text = tes3.findGMST(tes3.gmst.sRestIllegal).value
            if config.waitingPreset == constants.config.waitingPreset.VANILLA_RESTING and vanillaAllowRest == false then
                disallowResting(e, text)
            elseif config.waitingPreset == constants.config.waitingPreset.VANILLA_RESTING_AND_INNS and vanillaAllowRest == false and isPlayerInAnInn() == false then
                disallowResting(e, text)
            end
        end

    end

end

local function onUiShowRestMenu(e)

    -- managing the ui is not possible here so we have to pass it through to uiActivated handler
    isWaitRestScripted = e.scripted
    vanillaAllowRest = e.allowRest

    if config.restingPreset == constants.config.restingPreset.BEDS_AND_SCRIPTED then
        
        -- set allowRest to false so that resting menu is disabled in wilderness
        if e.scripted == true then
            e.allowRest = true
        else
            e.allowRest = false
        end

    end
    
end

event.register("uiShowRestMenu", onUiShowRestMenu)
event.register("uiActivated", onUiActivated, { filter = "MenuRestWait" })

event.register(constants.event.PLAYER_RESTED, function()
    local timestamp = tes3.getSimulationTimestamp()
    playerData.setLastRestedTimestamp(timestamp)
    playerData.setLastWaitedTimestamp(timestamp)
end)

event.register(constants.event.PLAYER_WAITED, function()
    playerData.setLastWaitedTimestamp(tes3.getSimulationTimestamp())
end)

print("[" .. modInfo.modName .. " " .. modInfo.modVersion .. "] Resting Module Loaded")