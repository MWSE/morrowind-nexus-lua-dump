local common = require("mer.darkShard.common")
local logger = common.createLogger("MovingPlatform")
local CraftingFramework = require("CraftingFramework")
local ReferenceManager = CraftingFramework.ReferenceManager

local UNITS_PER_SECOND = 40
local PLATFORM_RADIUS = 115
local PLATFORM_HEIGHT = 35
local HEIGHT_TOLERANCE = 5

local platforms = {
    afq_dwe_platform_act = {
        min = 14536,
        max = 14873,
    },
    afq_dwe_platform02_act = {
        min = 12128,
        max = 12483,
    },
}

local refManager = ReferenceManager:new{
    id = "DarkShard:MovingPlatform",
    requirements = function(self, reference)
        return platforms[reference.object.id:lower()] ~= nil
    end
}

---@param platformRef tes3reference
local function getNearbyRefs(platformRef)
    local nearbyRefs = {}
    local validObjectTypes = {
        [tes3.objectType.creature] = true,
        [tes3.objectType.npc] = true,
    }
    local platformSurfacePos = platformRef.position.z +(PLATFORM_HEIGHT * platformRef.scale)


    for ref in platformRef.cell:iterateReferences() do
        local validRef = validObjectTypes[ref.baseObject.objectType]
            or ref.object.weight ~= nil
        if validRef then
            local horizontalDistance = tes3vector2.new(ref.position.x, ref.position.y)
                :distance(tes3vector2.new(platformRef.position.x, platformRef.position.y))
            local verticalDistance = math.abs(ref.position.z - platformSurfacePos)
            if horizontalDistance < PLATFORM_RADIUS and verticalDistance < HEIGHT_TOLERANCE then
                logger:debug("Found nearby reference %s", ref.object.id)
                table.insert(nearbyRefs, ref)
            end
        end
    end
    return nearbyRefs
end

event.register("simulate", function(e)
    refManager:iterateReferences(function(reference)
        --1 is up, -1 is down
        local direction = reference.data.currentDirection or 1
        local height = reference.position.z
        local speed = UNITS_PER_SECOND * e.delta
        local platform = platforms[reference.object.id:lower()]
        --Change direction if we hit the max or min height
        if direction == 1 then
            if (height + speed) > platform.max then
                direction = -1
            end
        elseif direction == -1 then
            if (height - speed) < platform.min then
                direction = 1
            end
        end
        reference.data.currentDirection = direction
        local change =  tes3vector3.new(0, 0, speed * direction)
        for _, nearbyRef in ipairs(getNearbyRefs(reference)) do
            tes3.positionCell{
                reference = nearbyRef,
                position = nearbyRef.position + change,
                orientation = nearbyRef.orientation,
                cell = nearbyRef.cell,
            }
        end

        tes3.positionCell{
            reference = reference,
            position = reference.position + change,
            orientation = reference.orientation,
            cell = reference.cell,
        }
    end)
end)