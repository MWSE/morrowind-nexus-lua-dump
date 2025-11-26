local self = require'openmw.self'
local types = require'openmw.types'

local PlayerNoClothes = require'scripts.styxd.bdc.event.PlayerNoClothes'
local PlayerSomeClothes = require'scripts.styxd.bdc.event.PlayerSomeClothes'

local DECENCY_CRITICAL_EQUIPMENT_SLOTS = {
    types.Actor.EQUIPMENT_SLOT.Robe,
    types.Actor.EQUIPMENT_SLOT.Cuirass,
    types.Actor.EQUIPMENT_SLOT.Greaves,
    types.Actor.EQUIPMENT_SLOT.Pants,
    types.Actor.EQUIPMENT_SLOT.Shirt,
    types.Actor.EQUIPMENT_SLOT.Skirt
}

local function checkPlayerNaked(player)
    -- Having both the torso and legs exposed counts as "naked".
    for _, slot in ipairs(DECENCY_CRITICAL_EQUIPMENT_SLOTS) do
        if types.Actor.equipment(player, slot) ~= nil then
            return false
        end
    end

    return true
end

local playerWasPreviouslyNaked

return {
    engineHandlers = {
        onUpdate = function()
            if self.cell == nil then
                -- This would happen during loading of the game.
                -- The script shouldn't run then.
                return
            end

            local isPlayerNaked = checkPlayerNaked(self.object)

            if playerWasPreviouslyNaked == nil then
                -- Always set the state if we have no data from this session.
                if isPlayerNaked then
                    PlayerNoClothes.sendEvent(self.object)
                    playerWasPreviouslyNaked = true
                else
                    PlayerSomeClothes.sendEvent(self.object)
                    playerWasPreviouslyNaked = false
                end
            elseif isPlayerNaked then
                if not playerWasPreviouslyNaked then
                    PlayerNoClothes.sendEvent(self.object)
                    playerWasPreviouslyNaked = true
                end
            else
                if playerWasPreviouslyNaked then
                    PlayerSomeClothes.sendEvent(self.object)
                    playerWasPreviouslyNaked = false
                end
            end
        end
    }
}
