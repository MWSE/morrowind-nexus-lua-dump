local self = require("openmw.self")
local types = require("openmw.types")
local core = require("openmw.core")
local async = require("openmw.async")
local nearby = require("openmw.nearby")
local util = require("openmw.util")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")

local getPathfindingAgentBounds = types.Actor.getPathfindingAgentBounds
local getActiveEffects = types.Actor.activeEffects
local findPath = nearby.findPath

local UNITS_PER_FEET = 21.33333333
local MAX_ACTIVATE_DIST = core.getGMST("iMaxActivateDist")
local PATH_STATUS_SUCCESS = nearby.FIND_PATH_STATUS.Success
local PATH_STATUS_PARTIAL = nearby.FIND_PATH_STATUS.PartialPath

local myData = require("scripts.pursuit.pursuit_data")(self)

local function getPursueTarget()
    local activePackage = I.AI.getActivePackage()
    local packageType = activePackage and activePackage.type
    local inCombatOrPursue = packageType == "Combat" or packageType == "Pursue"
    return inCombatOrPursue and activePackage.target or nil
end

local function pursueTarget(e)
    local target, force = e.target, e.force
    if not types.Actor.canMove(self) then return end
    if not target then return end
    if force or target == getPursueTarget() then
        myData.target = target
        myData.pursuerPos = self.position
        myData.pursuerCell = self.cell.name
        myData.startTime = { realTime = os.time(), gameTime = core.getGameTime() }
        core.sendGlobalEvent("Pursuit_pursueTarget", myData)
    end
end

local function updatePaths()
    myData.pathDoor = {}
    myData.pathUpdated = false
    if not storage.globalSection("Settings!_Pursuit_!"):get("useNavmesh") then
        return
    end
    if not getPursueTarget() then
        return
    end
    local agentBounds = getPathfindingAgentBounds(self)
    local telekinesisRange = getActiveEffects(self):getEffect("telekinesis").magnitude -- in feet
    local activationDist = (telekinesisRange * UNITS_PER_FEET) + MAX_ACTIVATE_DIST

    for _, door in pairs(nearby.doors) do
        -- using groundDoorPos because some doors in the game are huge
        local groundDoorPos = util.vector3(door.position.x, door.position.y,
            door.position.z - door:getBoundingBox().halfSize.z)
        local pathStatus, pathList = findPath(self.position, groundDoorPos, {
            agentBounds = agentBounds,
            destinationTolerance = MAX_ACTIVATE_DIST
        })

        -- start at self.position, override if pathList is not empty
        local finalPoint = pathList[#pathList] or self.position
        -- this could be refined later for better accuracy
        local canActivate = (finalPoint - groundDoorPos):length() <= activationDist
        myData.pathDoor[door.id] = {
            pathList = pathList,
            door = door,
            canPath = pathStatus == PATH_STATUS_SUCCESS or (pathStatus == PATH_STATUS_PARTIAL and canActivate),
        }
    end

    myData.pathUpdated = true
end

local function updateState()
    core.sendGlobalEvent("Pursuit_updatePursuer", { pursuer = self, inPursue = getPursueTarget() })
end

-- deprecated: remove this after the next protective guards update and use `pursueTarget` directly
local function pursueTarget_ProtectiveGuards(target)
    pursueTarget({ target = target, force = true })
end

storage.globalSection("@Pursuit@"):subscribe(async:callback(function(name, key)
    if key == "updatePath" then updatePaths() end
    if key == "updateState" then updateState() end
end))

return {
    eventHandlers = {
        Pursuit_pursueTarget = pursueTarget,
        Pursuit_pursueTarget_ProtectiveGuards = pursueTarget_ProtectiveGuards
    }
}
