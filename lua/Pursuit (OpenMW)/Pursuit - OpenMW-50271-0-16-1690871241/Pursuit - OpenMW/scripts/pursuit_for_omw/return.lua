local self = require("openmw.self")
local ai = require("openmw.interfaces").AI
local types = require("openmw.types")
local core = require("openmw.core")
local util = require("openmw.util")
local aux = require("scripts.pursuit_for_omw.auxiliary")
local storage = require("openmw.storage")
local async = require("openmw.async")
local nearby = require("openmw.nearby")
local SettingsPursuitMain = storage.globalSection("SettingsPursuitMain")

local oripos = self.startingPosition -- (only available in v0.49 and newer)
-- There is no data yet to get starting cell of an actor
-- For now, just get the cell where pursuit first commenced
local oricell
local returned = true
local isReturning = false
local inactiveNearestDoor = nil
local myActiveTarget = ai.getActiveTarget
local getHealth = types.Actor.stats.dynamic.health
local firstActive = false
local canReturn = true
-- target is optional
local function hasFollowEscortPackage(target)
    local following = false
    ai.forEachPackage(function(package)
        local pkgType = package.type
        local correctTarget = target == nil or target == package.target
        local follow_or_escort = pkgType == "Follow" or pkgType == "Escort"
        if follow_or_escort and correctTarget then
            following = true
            return
        end
    end)
    return following
end

local function isAggro()
    local aggroTarget = myActiveTarget("Combat") or myActiveTarget("Pursue")
    return aggroTarget and types.Actor.stats.dynamic.health(aggroTarget).current > 0
end

local clearMethod = {
    __index = function(t, k)
        if k == "clear" then
            return function(this, returnIsEnabled)
                -- not 'this = {}' because the metatable attached will be lost
                for _ in pairs(this) do
                    this[_] = nil
                end
                this[#this + 1] = oricell
                if returnIsEnabled then
                    ai.startPackage {
                        type = "Wander",
                        distance = 2048,
                        cancelOther = false
                    }
                    returned = true
                    isReturning = false
                    inactiveNearestDoor = nil
                end
            end
        end
    end
}

local cellsTraversed = setmetatable({}, clearMethod)

local function can_Return()
    return canReturn and not isAggro() and not hasFollowEscortPackage()
end

local function return_back()
    if getHealth(self).current < 1 or not self:isActive() then
        return
    end
    async:newUnsavableSimulationTimer(math.random() + 1, return_back)

    if not SettingsPursuitMain:get("Actor Return") then
        cellsTraversed:clear(false)
        return
    end
    if firstActive then
        firstActive = false
        return
    end

    if not returned and can_Return() then
        if oripos and self.cell.name == oricell then
            ai.startPackage {
                type = "Travel",
                destPosition = oripos
            }
            if (oripos - self.position):length2() < 50 * 50 then
                cellsTraversed:clear(true)
            end
        else
            local nearestDoor
            for _, cellName in ipairs(cellsTraversed) do
                nearestDoor = select(3, aux.findNearestDoorToCell(self.position, cellName, nearby.doors, oripos))
                if nearestDoor then
                    break
                end
            end
            if nearestDoor then
                ai.startPackage {
                    type = "Travel",
                    destPosition = nearestDoor.position,
                    cancelOther = false
                }
                isReturning = true
                inactiveNearestDoor = nearestDoor

                local selfposV2 = util.vector2(self.position.x, self.position.y)
                local doorposV2 = util.vector2(nearestDoor.position.x, nearestDoor.position.y)

                if (selfposV2 - doorposV2):length2() < 100 * 100 then
                    nearestDoor:activateBy(self)
                    ai.removePackages("Travel")
                    core.sendGlobalEvent("Pursuit_teleportToDoorDest_eqnx", {
                        nearestDoor,
                        self
                    })
                end
            end
        end
    end
end

async:newUnsavableSimulationTimer(0, return_back)

return {
    interfaceName = "PURSUIT_RETURN",
    interface = {
        version = require("scripts.pursuit_for_omw.modInfo").MOD_VERSION,
        canReturn = function(bool)
            if bool == nil then
                return canReturn
            end
            canReturn = bool
            return canReturn
        end
    },
    engineHandlers = {
        onSave = function()
            return {
                oripos = oripos,
                oricell = oricell,
                cellsTraversed = cellsTraversed,
                returned = returned
            }
        end,
        onLoad = function(savedData)
            if savedData then
                oripos = savedData.oripos
                oricell = savedData.oricell
                cellsTraversed = savedData.cellsTraversed
                returned = savedData.returned
                setmetatable(cellsTraversed, clearMethod)
            end
        end,
        onInactive = function()
            -- what happens when self is returning but goes inactive
            if not returned and isReturning and inactiveNearestDoor and (self.cell == inactiveNearestDoor.cell) then
                core.sendGlobalEvent("NPC_RETURN_Inactive_Return_eqnx", {
                    actor = self,
                    door = inactiveNearestDoor
                })
                isReturning = true
                inactiveNearestDoor = nil
            end
        end,
        onActive = function()
            -- timer ticks even inactive, dont trigger callback yet now
            firstActive = true
        end
    },
    eventHandlers = {
        NPC_RETURN_returnInit_eqnx = function(e)
            if not oricell and not hasFollowEscortPackage() then
                oripos, oricell = e.position, e.cellName
            end
        end,
        NPC_RETURN_updateCell_eqnx = function(e)
            cellsTraversed[#cellsTraversed + 1] = e.prevCell
            cellsTraversed[#cellsTraversed + 1] = e.cellName
            returned = false
        end,
        NPC_RETURN_returnToOricellInstant_eqnx = function()
            if not returned and can_Return() then
                core.sendGlobalEvent("NPC_RETURN_returnToOriCellInstantly_eqnx", {
                    self,
                    oricell,
                    oripos
                })
                cellsTraversed:clear(true)
            end
        end
    }
}
