local types = require("openmw.types")
local time = require("openmw_aux.time")
local self = require("openmw.self")
local core = require("openmw.core")
require("scripts.ItBeats.heartbeat")
require("scripts.ItBeats.cellBlacklist")

PlayerState = {
    inRM = self.cell.region == "red mountain region",
    heartIsDead = types.Player.quests(self)["C3_DestroyDagoth"].stage >= 20
}

local function updateCurrentRegion()
    local cell = self.cell
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
            if questId == "C3_DestroyDagoth" and stage == 20 then
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
