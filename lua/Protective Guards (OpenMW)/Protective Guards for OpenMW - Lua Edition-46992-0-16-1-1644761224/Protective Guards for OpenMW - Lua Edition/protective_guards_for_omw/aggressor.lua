local self = require("openmw.self")
local nearby = require("openmw.nearby")
local time = require("openmw_aux.time")
local ai = require('openmw.interfaces').AI
local core = require("openmw.core")
local bL = require("protective_guards_for_omw.blacklistedareas")
local firstRun = false
local previousCell
local distCheck = 8192

local function searchGuardsAdjacentCells()
    if not firstRun then
        return
    end
    local nearbyDoors = {}
    for _, door in ipairs(nearby.doors) do
        if
            not nearbyDoors[door.destCell] and door.destCell ~= previousCell and door.isTeleport and
                (door.position - self.position):length() < distCheck
         then
            nearbyDoors[door.destCell] = door
            core.sendGlobalEvent("ProtectiveGuards_searchGuards_eqnx", {door, self})
        end
    end
end

time.runRepeatedly(
    function()
        if bL[self.cell.name] then
            return
        end
        if not ai.getActiveTarget('Combat') or not self:canMove() then
            firstRun = true
            return
        end

        local playerRef

        if ai.getActiveTarget('Combat').type == "Player" then
            playerRef = ai.getActiveTarget('Combat')
            if playerRef.inventory:countOf("PG_TrigCrime") > 0 then
                return
            end
            for _, actor in ipairs(nearby.actors) do
                if
                    actor ~= self.object and actor.type == "NPC" and
                        (actor.position - self.position):length() < distCheck and
                        (string.match(actor.recordId, "guard") or string.match(actor.recordId, "ordinator") or
                            (actor:getEquipment()[1] and actor:getEquipment()[1].recordId:match("imperial") and
                                self.cell.name:match("Gnisis")))
                 then
                    if math.random(5) < 3 then
                        actor:sendEvent("ProtectiveGuards_alertGuard_eqnx", self)
                    end
                end
            end
            searchGuardsAdjacentCells()
            firstRun = false
        end
    end,
    0.5 * time.second
)

--aux.runEveryNSeconds(0.5, selfIsHostileCheck)
time.runRepeatedly(
    function()
        firstRun = true
    end,
    math.pi * time.second
)

return {
    engineHandlers = {
        onInactive = function()
            firstRun = true
            previousCell = self.cell
        end,
        onActive = function()
            distCheck = self.cell.isExterior and 8192 / 5 or 8192
        end
    }
}