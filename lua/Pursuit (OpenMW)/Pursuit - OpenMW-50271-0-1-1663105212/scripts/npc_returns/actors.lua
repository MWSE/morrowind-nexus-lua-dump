local self = require("openmw.self")
local ai = require("openmw.interfaces").AI
local types = require("openmw.types")
local time = require("openmw_aux.time")
local aux_util = require("openmw_aux.util")
local nearby = require("openmw.nearby")
local core = require("openmw.core")
local util = require("openmw.util")
local I = require("openmw.interfaces")

local hasFollowAI = false
local isReturning = false
local oricell
local oripos
local cellsTraversed = {}
local rTimer
local r2Timer
local players = {}

function include(moduleName)
    local status, result = pcall(require, moduleName)
    if (status) then
        return result
    end
end

local auxiliary = include("scripts.pursuit_for_omw.auxiliary") -- from Pursuit mod

local function findVal(t, o)
    for i, v in pairs(t) do
        if v == o then
            return i
        end
    end
end

local function isDead(obj)
    local health = types.Actor.stats.dynamic.health(obj)
    return health.current <= 0
end

local function isAggressive()
    local aggressive = false
    ai.forEachPackage(function(package)
        if (package.type == "Combat" or package.type == "Pursue") then
            aggressive = true
            return
        end
    end)
    return aggressive
end

local function isFollower()
    local following = false
    ai.forEachPackage(function(package)
        if (package.type == "Follow" or package.type == "Escort") then
            following = true
            return
        end
    end)
    return following
end

local function savePos_eqnx()
    -- save the original position and cell of this NPC
    oricell = oricell or self.cell.name
    oripos = oripos or self.position
    if cellsTraversed[1] ~= oricell then
        table.insert(cellsTraversed, 1, oricell)
    end
end

local function playerIsInSameCell()
    -- check if there are nearby players
    players = aux_util.mapFilter(nearby.actors, function(actor)
        return actor.type == types.Player
    end)
    return #players > 0
end

local function returnToCell(targetCell, bestDoor)
    -- teleport this NPC to its original position and cell
    core.sendGlobalEvent("NPC_Returns_goBackToStartingPosition_eqnx", {
        object = self.object,
        cell = targetCell or oricell,
        position = bestDoor and types.Door.destPosition(bestDoor) or oripos
    })
end

local function travelToNearestDoor_returnCell()
    -- this feature only works if Pursuit mod is installed

    if not auxiliary then
        return
    end

    if self.type ~= types.NPC then
        return
    end

    if hasFollowAI then
        return
    end

    -- orders this NPC to "walk" to the door that leads to his original cell (or the cell that leads to his original cell)
    if playerIsInSameCell() and self.cell.name ~= oricell then
        if (ai.getActivePackage() and
            (ai.getActivePackage().type == "Wander" or ai.getActivePackage().type == "Unknown")) or
            not ai.getActivePackage() or isReturning then
            local bestDoor
            local targetCell

            bestDoor = auxiliary.getBestDoor(self, oricell, nil, oripos, nearby.doors)

            if not bestDoor and #cellsTraversed > 0 then
                for _, previousCell in ipairs(cellsTraversed) do
                    bestDoor = auxiliary.getBestDoor(self, previousCell, nil, oripos, nearby.doors)
                    targetCell = previousCell
                    if bestDoor then
                        break
                    end
                end
            end

            if not bestDoor then
                print(types.NPC.record(self).name .. " is not returning to " .. tostring(targetCell))
                local durs = aux_util.mapFilter(nearby.doors, function(door)
                    return types.Door.destCell(door)
                end)
                for _, door in ipairs(durs) do
                    if not findVal(cellsTraversed, types.Door.destCell(door)) then
                        table.insert(cellsTraversed, types.Door.destCell(door).name)
                    end
                end
            end

            if bestDoor and not isReturning then
                -- we order this NPC to travel (walk) to the door
                self:sendEvent("StartAIPackage", {
                    type = "Travel",
                    destPosition = bestDoor.position
                })
                isReturning = types.Door.destCell(bestDoor)
                print(types.NPC.record(self).name .. " is returning to " .. tostring(oricell))
            end

            --// not vector3 because it doesnt give correct results especially for large doors
            local selfposV2 = util.vector2(self.position.x, self.position.y)
            local doorposV2 = util.vector2(bestDoor.position.x, bestDoor.position.y)
            local distV2 = (selfposV2 - doorposV2):length()

            if bestDoor and distV2 < 100 -- (self.position - bestDoor.position):length() - 50 <= math.abs(self.position.z - bestDoor.position.z)
            then
                -- NPC cannot use teleport doors, but this plays the "open door" sound (waiting for proper sound API)
                bestDoor:activateBy(self)
                returnToCell(targetCell, bestDoor)
                isReturning = false
                self:sendEvent("StartAIPackage", {
                    type = "Wander",
                    distance = 2048
                })
            end
        end
    end
end

rTimer = time.runRepeatedly(travelToNearestDoor_returnCell, math.random(3, 4) * time.second)

r2Timer = time.runRepeatedly(function()
    if isFollower() then
        hasFollowAI = true
        r2Timer()
    end
end, math.random() * time.second, {
    type = time.GameTime
})

return {
    engineHandlers = {
        onLoad = function(data)
            if data then
                oricell, oripos, cellsTraversed, hasFollowAI = unpack(data)
            end
        end,
        onSave = function()
            return {oricell, oripos, cellsTraversed, hasFollowAI}
        end,
        onInactive = function()
            if isDead(self) then
                rTimer()
                return
            end
            if self.type ~= types.NPC then
                return
            end
            savePos_eqnx()

            if isFollower() then
                return
            end

            local aiTarget
            if ai.getActiveTarget("Combat") or ai.getActiveTarget("Pursue") then
                aiTarget = ai.getActivePackage().target
            end

            if aiTarget and not isDead(aiTarget) and (self.position - aiTarget.position):length() < 8192 then
                return
            end

            if hasFollowAI then
                return
            end

            if isReturning then
                ai.removePackages("Travel")
            end

            -- if this NPC goes inactive, travelToNearestDoor_returnCell function will not run. This is a simple way to circumvent that.
            if #players > 0 then
                core.sendGlobalEvent("NPC_Returns_return_eqnx", {
                    cell = oricell,
                    position = oripos,
                    actor = self,
                    player = players[1]
                })
            end
            -- returnToCell()
        end,
        onActive = function()
            savePos_eqnx()
            if self.cell.name == oricell and not isAggressive() and not isFollower() then
                cellsTraversed = {}
                table.insert(cellsTraversed, self.cell.name)
            end
            if findVal(cellsTraversed, self.cell.name) then
                return
            else
                -- saves the cells that this NPC has traversed
                table.insert(cellsTraversed, self.cell.name)
            end
        end
    },
    eventHandlers = {
        NPC_returns_savePos_eqnx = savePos_eqnx,
        travelToNearestDoor_returnCell = travelToNearestDoor_returnCell
    }
}
