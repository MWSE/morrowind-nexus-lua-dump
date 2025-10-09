local types = require("openmw.types")
local time = require("openmw_aux.time")
local self = require("openmw.self")
local core = require("openmw.core")
require("scripts.ItBeats.heartbeat")
require("scripts.ItBeats.cellBlacklist")

PlayerState = {
    inRM = self.cell and self.cell.region == "red mountain region" or false,
    heartIsDead = types.Player.quests(self)["C3_DestroyDagoth"].stage >= 20
}

local function updateCurrentRegion()
    local cell = self.cell
    -- safety measure
    -- actually happens on the character creation,
    -- when the player doesn't exist yet, but mod needs to initialize
    if not cell then return end
    -- in case you have a player home with teleports, for example
    if BlacklistedInteriors[string.lower(cell.name)] then return end

    if cell.isExterior then
        PlayerState.inRM = cell.region == "red mountain region"
    else
        core.sendGlobalEvent("isCellInRM", cell.id)
    end
end

time.runRepeatedly(
    updateCurrentRegion,
    1 * time.second,
    { type = time.SimulationTime })

return {
    engineHandlers = {
        onQuestUpdate = function (questId, stage)
            if string.lower(questId) == "c3_destroydagoth" and stage == 20 then
                PlayerState.heartIsDead = true
            end
        end
    },
    eventHandlers = {
        updateInRM = function (status)
            PlayerState.inRM = status
        end
    }
}
