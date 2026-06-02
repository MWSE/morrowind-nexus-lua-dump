local world = require('openmw.world')
local types = require('openmw.types')
local util  = require('openmw.util')

local player = nil

local function findPlayer()
    for _, actor in ipairs(world.activeActors) do
        if actor.type == types.Player then
            return actor
        end
    end
    return nil
end

local function onPlayerAdded(p)
    player = p
    print("[sit-global] onPlayerAdded: player saved.")
end

local function onSitTeleport(eventData)
    if not player then
        player = findPlayer()
        if not player then
            print("[sit-global] ERROR: player not found")
            return
        end
        print("[sit-global] Player found via activeActors.")
    end

    if eventData.furniture and eventData.furniturePos then
        local furn   = eventData.furniture
        local newPos = eventData.furniturePos
        local delta  = newPos - furn.position
        if math.sqrt(delta.x^2 + delta.y^2) > 0.5 then
            print(string.format("[sit-global] Moving chair by (%.1f, %.1f)",
                delta.x, delta.y))
            furn:teleport(furn.cell, newPos, { rotation = furn.rotation })
        end
    end

    local pos = eventData.position
    local yaw = eventData.yaw
--    print(string.format("[sit-global] Teleporting player to (%.1f, %.1f, %.1f)",
--        pos.x, pos.y, pos.z))
    player:teleport(player.cell, pos,
        { rotation = util.transform.rotateZ(yaw + math.pi) })

    player:sendEvent('SitAnimStart', {})
end

local function onSitRestoreChair(eventData)
    local furniture = eventData.furniture
    local pos       = eventData.position
    local rot       = eventData.rotation

    if not furniture then
        print("[sit-global] SitRestoreChair: furniture ref is nil")
        return
    end

    furniture:teleport(furniture.cell, pos, { rotation = rot })

--    print(string.format("[sit-global] Chair restored to (%.1f, %.1f, %.1f)",
--        pos.x, pos.y, pos.z))
end

local function onSitPushChair(eventData)
    local furniture = eventData.furniture
    local pos       = eventData.position

    if not furniture then
        print("[sit-global] SitPushChair: furniture ref is nil")
        return
    end

    furniture:teleport(furniture.cell, pos, { rotation = furniture.rotation })

--    print(string.format("[sit-global] Chair moved to (%.1f, %.1f, %.1f)",
--        pos.x, pos.y, pos.z))

    if player then
        player:sendEvent('SitChairReady', {
            furniture = furniture,
            newPos    = pos,
        })
    else
        print("[sit-global] SitPushChair: player ref lost")
    end
end

return {
    engineHandlers = {
        onPlayerAdded = onPlayerAdded,
    },
    eventHandlers = {
        SitTeleport     = onSitTeleport,
        SitPushChair    = onSitPushChair,
        SitRestoreChair = onSitRestoreChair,
    }
}
