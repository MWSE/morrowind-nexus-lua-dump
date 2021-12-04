local self = require("openmw.self")
local nearby = require("openmw.nearby")
local aux = require("openmw_aux.util")
local core = require("openmw.core")
local bL = require("protective_guards_for_omw.blacklistedareas")
local firstRun = false
local previousCell

local function searchGuardsAdjacentCells()
    if not firstRun then
        return
    end
    local doorDistCheck = 8192
    local tempTab = {}
    if self.cell.isExterior then
        doorDistCheck = doorDistCheck / 5
    end
    for _, door in nearby.doors:ipairs() do
        if
            door.destCell ~= previousCell and door.isTeleport and
                (door.position - self.position):length() < doorDistCheck
         then
            tempTab[tostring(door)] = door
        end
    end
    for _, door in pairs(tempTab) do
        core.sendGlobalEvent("ProtectiveGuards_searchGuards_eqnx", {door, self.object})
    end
end

local function selfIsHostileCheck()
    if bL[self.cell.name] then
        return
    end
    if not self:getCombatTarget() or not self:canMove() then
        firstRun = true
        return
    end
    local playerRef
    local distCheck = 8192
    if self.cell.isExterior then
        distCheck = distCheck / 4
    end
    if self:getCombatTarget().type == "Player" then
        playerRef = self:getCombatTarget()
        if playerRef.inventory:countOf("PG_TrigCrime") > 0 then
            return
        end
        for _, actor in nearby.actors:ipairs() do
            if
                actor ~= self.object and actor.type == "NPC" and (actor.position - self.position):length() < distCheck and
                    (string.match(actor.recordId, "guard") or string.match(actor.recordId, "ordinator") or
                        (actor:getEquipment()[1] and actor:getEquipment()[1].recordId:match("imperial") and self.cell.name:match("Gnisis")))
             then
				if math.random(5) < 3 then
                actor:sendEvent("ProtectiveGuards_alertGuard_eqnx", self.object)
				end
            end
        end
        searchGuardsAdjacentCells()
        firstRun = false
    end
end

aux.runEveryNSeconds(0.5, selfIsHostileCheck)
aux.runEveryNSeconds(
    3,
    function()
        firstRun = true
    end
)

return {
    engineHandlers = {
        onLoad = function()
            aux.runEveryNSeconds(0.5, selfIsHostileCheck)
            aux.runEveryNSeconds(
                3,
                function()
                    firstRun = true
                end
            )
        end,
        onInactive = function()
            firstRun = true
            previousCell = self.cell
        end
    }
}
