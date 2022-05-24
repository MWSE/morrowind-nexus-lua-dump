local core = require('openmw.core')
local util = require('openmw.util')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'AttendMe',
    l10n = 'AttendMe',
    name = "Attend me",
    description = "Follower HUD and convenience",
}

local followers = {}
local followersToTeleport = {}

local function cleanFollowers()
    local index = 1
    while index <= #followers do
        local follower = followers[index]
        if follower:isValid() and follower.count > 0 then
            index = index + 1
        else
            table.remove(followers, index)
        end
    end
end

local hud = require('scripts.AttendMe.hud')(followers)

local maxTeleportDistance = 175
local minTeleportDistance = 100
local unit = util.vector3(1, 0, 0) * maxTeleportDistance
local verticalAxis = util.vector3(0, 0, 1)
local function teleportFollowers()
    if #followersToTeleport == 0 then return end
    -- offset to waist height to accomodate uneven terrain
    local playerPosition = self.position + verticalAxis * 50
    local foundTargets = {}
    -- search for unoccupied positions around the player
    -- prefer cardinal positions
    local searchFactor = 2
    while searchFactor <= 32 do
        for offset = 1, searchFactor do
            if offset % 2 == 1 or searchFactor == 2 then
                local angle = offset * math.pi / searchFactor
                local rotatedUnit = util.transform.rotate(angle, verticalAxis) * unit
                local target = playerPosition + rotatedUnit
                local result = nearby.castRay(playerPosition, target)
                if result.hit then
                    target = result.hitPos
                    if (target - playerPosition):length() < minTeleportDistance then
                        target = nil
                    end
                end
                if target then
                    table.insert(foundTargets, target)
                    if #foundTargets == #followersToTeleport then break end
                end
            end
        end
        if #foundTargets == #followersToTeleport then break end
        searchFactor = searchFactor * 2
    end

    for i, follower in ipairs(followersToTeleport) do
        local target = foundTargets[i] or self.position
        core.sendGlobalEvent('AttendMeTeleport', {
            actor = follower,
            cellName = self.cell.name,
            position = target,
        })
    end

    followersToTeleport = {}
end

return {
    eventHandlers = {
        AttendMeFollowerStatus = function(e)
            local index = nil
            for i, follower in pairs(followers) do
                if follower == e.actor then
                    index = i
                    break
                end
            end
            if e.status and not index then
                table.insert(followers, e.actor)
            end
            if not e.status and index then
                table.remove(followers, index)
            end
            hud.updateFollowerList()
        end,
        AttendMeFollowerAway = function(e)
            table.insert(followersToTeleport, e.actor)
        end,
    },
    engineHandlers = {
        onUpdate = function()
            cleanFollowers()
            teleportFollowers()
            hud.updateFollowerList()
        end,
    },
}
