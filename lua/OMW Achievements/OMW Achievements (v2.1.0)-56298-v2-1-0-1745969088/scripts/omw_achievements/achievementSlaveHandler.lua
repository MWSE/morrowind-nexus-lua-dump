local types = require('openmw.types')
local self = require('openmw.self')
local interfaces = require('openmw.interfaces')
local achievements = require('scripts.omw_achievements.achievements.achievements')

local sk00maUtils = require('scripts.omw_achievements.utils.sk00maUtils')

isSlaveDialogue = false
currentSlave = nil

local function UiModeChanged(data)

    --- Check for unique achievement "Abolitionist"
    local slot = types.Actor.EQUIPMENT_SLOT
    local macData = interfaces.storageUtils.getStorage("counters")
    local slavesCounter = macData:get("slavesCounter")

    if data.newMode == "Dialogue" then
        local npc = data.arg
        if (types.Actor.getEquipment(npc, slot.LeftGauntlet) ~= nil and types.Actor.getEquipment(npc, slot.LeftGauntlet).recordId == "slave_bracer_left") or (types.Actor.getEquipment(npc, slot.RightGauntlet) ~= nil and types.Actor.getEquipment(npc, slot.RightGauntlet).recordId == "slave_bracer_right") then
            isSlaveDialogue = true
            currentSlave = npc
        end
    end

    if data.oldMode == "Dialogue" and isSlaveDialogue == true then
        isSlaveDialogue = false
        if (types.Actor.getEquipment(currentSlave, slot.LeftGauntlet) == nil) and (types.Actor.getEquipment(currentSlave, slot.RightGauntlet) == nil) then
            slavesCounter = slavesCounter + 1
            macData:set("slavesCounter", slavesCounter)

            if slavesCounter >= 50 then
                slavesAchievement = sk00maUtils.getAchievementById(achievements, "free_slaves_01")
                self.object:sendEvent('gettingAchievement', slavesAchievement)
            end

        end
    end

end

return {
    eventHandlers = {
        UiModeChanged = UiModeChanged
    }
}