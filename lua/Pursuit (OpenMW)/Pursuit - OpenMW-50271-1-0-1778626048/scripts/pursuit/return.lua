local self = require("openmw.self")
local types = require("openmw.types")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local aux_util = require("openmw_aux.util")
local async = require("openmw.async")
local storage = require("openmw.storage")
local nearby = require("openmw.nearby")
local util = require("openmw.util")
local anim = require("openmw.animation")
local modInfo = require("scripts.pursuit.modInfo")

local ORI_ROT = self.startingRotation                         -- (0.49++)
local ORI_POS = self.startingPosition                         -- (0.49++)
local ORI_CELL = self.startingCell and self.startingCell.name -- (v0.51++)

local RETURN_DIST_THRESHOLD = 32
local MAX_ACTIVATE_DIST = core.getGMST("iMaxActivateDist")
local PATH_STATUS_SUCCESS = nearby.FIND_PATH_STATUS.Success

local myActiveTarget = I.AI.getActiveTarget
local findPath = nearby.findPath

local myLowerBody = nil

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

local timeControl = {
    time = 0,
    control = math.random(),
    reset = function(timeControl)
        timeControl.time = 0
        timeControl.control = math.random()
    end
}

local _meta = {}
_meta.__index = _meta

function _meta:reset()
    local returnIsEnabled = storage.globalSection("Settings!_Pursuit_!"):get("actorReturn")
    if returnIsEnabled then
        self.cellsTraversed = {} -- {cellName = string, position = util.vector3}
        self.returned = true
        self.isReturning = false
        self.inactiveNearestDoor = nil
    end
end

function _meta:updateCell(data)
    local prevCellName, newCellName = data.pursuerCell, data.new_pursuerCell
    local prevPosition, newPosition = data.pursuerPos, data.new_pursuerPos
    if self.cellsTraversed[#self.cellsTraversed] == nil then
        self.cellsTraversed[1] = {} -- the first entry
    end
    if (self.cellsTraversed[#self.cellsTraversed].cellName ~= prevCellName) then
        self.cellsTraversed[#self.cellsTraversed] = { cellName = prevCellName, position = prevPosition }
    end
    if prevCellName ~= newCellName then
        self.cellsTraversed[#self.cellsTraversed + 1] = { cellName = newCellName, position = newPosition }
    end
end

local myReturn = setmetatable({
    version = modInfo.MOD_VERSION,
    cellsTraversed = {},
    returned = true,
    isReturning = false,
    inactiveNearestDoor = nil,
}, _meta)

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

local function hasFollowEscortPackage()
    local following = false
    I.AI.forEachPackage(function(package)
        local pkgType = package.type
        local follow_or_escort = pkgType == "Follow" or pkgType == "Escort"
        if follow_or_escort then
            following = true
            return
        end
    end)

    return following
end

local function removeTravelPackageByDestPosition(pos)
    I.AI.filterPackages(function(package)
        if package.type == "Travel" and package.destPosition == pos then
            return false
        end
        return true -- important because return nil removes the package!
    end)
end

local function isAggro()
    local aggroTarget = myActiveTarget("Combat") or myActiveTarget("Pursue")
    return aggroTarget and not types.Actor.isDead(aggroTarget)
end

local function deadOrFightingOrFollowingOrEscorting()
    return types.Actor.isDead(self) or isAggro() or hasFollowEscortPackage()
end

local function isTravellingToPosition(pos)
    local activePkg = I.AI.getActivePackage()
    return activePkg and activePkg.type == "Travel" and activePkg.destPosition == pos
end

local function pathToPositionIsOk(object, pos)
    local pathStatus = findPath(object.position, pos, {
        agentBounds = types.Actor.getPathfindingAgentBounds(object),
        destinationTolerance = MAX_ACTIVATE_DIST
    })
    return pathStatus == PATH_STATUS_SUCCESS
end

local function findMyselfNearestDoorBack(i, skipPathing)
    local traversed = myReturn.cellsTraversed[i]
    local nearestDoor, distanceToDoor = aux_util.findMinScore(nearby.doors, function(door)
        local isTeleport = types.Door.isTeleport(door)

        -- only teleport doors
        if not isTeleport then return false end

        local doorDestCellName = types.Door.destCell(door).name
        local traversedCell = traversed.cellName

        -- only doors that lead back
        if doorDestCellName ~= traversedCell then return false end

        if not skipPathing then
            -- only doors that can path to
            local pathOk = pathToPositionIsOk(self, door.position)
            if not pathOk then
                -- try using lastPos
                local nexttraversed = myReturn.cellsTraversed[i + 1]
                if not nexttraversed or not pathToPositionIsOk(self, nexttraversed.position) then
                    return
                end
            end
        end

        -- trick; get the nearest to the last position we were in this cell
        -- e.g Arrile's Tradehouse(mw) has two sections that are disconnected
        -- and usually these sections are very far apart inside (mods can mess with this, but unlikely)
        -- in future updates, we should use pathDoor data which is more accurate
        local distanceToDoor = (self.position - door.position):length()
        local doorDestPosition = types.Door.destPosition(door)
        local traversedPos = traversed.position
        local distanceFromDoorDestPosToLastPosInDoorDestCell = (doorDestPosition - traversedPos):length()

        return distanceToDoor + distanceFromDoorDestPosToLastPosInDoorDestCell
    end)
    return nearestDoor
end

local function disconnectedReturn(skipPathing)
    if myReturn.inactiveNearestDoor and isTravellingToPosition(myReturn.inactiveNearestDoor.position) then
        return
    end
    local nearestDoor
    for i in ipairs(myReturn.cellsTraversed) do
        nearestDoor = findMyselfNearestDoorBack(i, skipPathing)
        if nearestDoor then break end
    end
    if nearestDoor then
        local selfposV2 = util.vector2(self.position.x, self.position.y)
        local doorposV2 = util.vector2(nearestDoor.position.x, nearestDoor.position.y)
        if (selfposV2 - doorposV2):length() < MAX_ACTIVATE_DIST then
            local destCellName = nearestDoor.type.destCell(nearestDoor).name
            local destPosition = nearestDoor.type.destPosition(nearestDoor)
            local destRotation = nearestDoor.type.destRotation(nearestDoor)
            core.sendGlobalEvent("Pursuit_safeTeleport", { self, destCellName, destPosition, destRotation })
            removeTravelPackageByDestPosition(nearestDoor.position)
            return
        end
        if isTravellingToPosition(nearestDoor.position) then return end
        I.AI.startPackage {
            type = "Travel",
            destPosition = nearestDoor.position,
            cancelOther = false
        }
        myReturn.isReturning = true
        myReturn.inactiveNearestDoor = nearestDoor
    end
end

local function returnBack()
    if deadOrFightingOrFollowingOrEscorting() then return end

    if not myReturn.returned then
        local pos
        if self.cell.name == ORI_CELL then
            pos = ORI_POS
        elseif myReturn.cellsTraversed[1].cellName == self.cell.name then
            pos = myReturn.cellsTraversed[1].position
        end
        if pos then -- we've reached our initial cell..
            if (self.position - pos):length() < RETURN_DIST_THRESHOLD then
                removeTravelPackageByDestPosition(pos)
                myReturn:reset()
                return
            end
            if isTravellingToPosition(pos) then return end
            if pathToPositionIsOk(self, pos) then
                I.AI.startPackage {
                    type = "Travel",
                    destPosition = pos,
                    cancelOther = false,
                }
            else
                -- we are in the same cell but unable to path to original position
                -- return via doors that lead to it
                local skipPathing = true
                disconnectedReturn(skipPathing)
            end
        else
            disconnectedReturn()
        end
    end
end

local cap_kapak = async:callback(function(name, key)
    if key == "returnStartingCell" then -- name == "@Pursuit@"
        if myReturn.inactiveNearestDoor then
            removeTravelPackageByDestPosition(myReturn.inactiveNearestDoor.position)
        end
        myReturn:reset()
    end
end)

storage.globalSection("@Pursuit@"):subscribe(cap_kapak)

return {
    engineHandlers = {
        onSave = function()
            return myReturn
        end,
        onLoad = function(savedData)
            if savedData and savedData.version == myReturn.version then
                for k, v in pairs(savedData) do
                    myReturn[k] = v
                end
            end
        end,
        -- onActive = function() -- release in next version
        --     if deadOrFightingOrFollowingOrEscorting() then return end
        --     if (self.startingPosition - self.position):length() <= RETURN_DIST_THRESHOLD then
        --         core.sendGlobalEvent("Pursuit_safeTeleport",
        --             { self, self.cell.name, self.startingPosition, self.startingRotation })
        --     end
        -- end,
        onInactive = function()
            -- what happens when this actor is returning but goes inactive
            local inactiveNearestDoor = myReturn.inactiveNearestDoor
            if not myReturn.returned and myReturn.isReturning and inactiveNearestDoor and (self.cell == inactiveNearestDoor.cell) then
                core.sendGlobalEvent("Pursuit_Return_InactiveReturn", {
                    actor = self,
                    door = myReturn.inactiveNearestDoor,
                    isRunning = myLowerBody and myLowerBody:sub(1, 3) == "run" -- self.controls.run doesn't work
                })
                removeTravelPackageByDestPosition(inactiveNearestDoor.position)
                myReturn.isReturning = false
                myReturn.inactiveNearestDoor = nil
            end
        end,
        onUpdate = function(dt)
            if timeControl.time < timeControl.control then
                timeControl.time = timeControl.time + dt
                return
            end
            timeControl:reset()
            if storage.globalSection("Settings!_Pursuit_!"):get("actorReturn") then
                returnBack()
                myLowerBody = anim.getActiveGroup(self, anim.BONE_GROUP.LowerBody) -- does not work(error) when I'm inactive
            end
        end
    },
    eventHandlers = {
        Pursuit_Return_updateCell = function(data)
            myReturn.returned = false
            myReturn:updateCell(data)
        end,
        Pursuit_Return_startingCellReturn = function()
            if not myReturn.returned and not deadOrFightingOrFollowingOrEscorting() then
                local initial = myReturn.cellsTraversed[1] or {}
                core.sendGlobalEvent("Pursuit_Return_startingCellReturn", {
                    actor = self,
                    startingCellName = initial.cellName or ORI_CELL, -- fallback to original cell
                    startingPosition = initial.position or ORI_POS,  -- fallback to original position
                })
            end
        end,
    }
}
