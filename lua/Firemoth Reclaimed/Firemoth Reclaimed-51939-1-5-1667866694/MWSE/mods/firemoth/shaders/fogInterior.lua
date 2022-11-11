local fog = require("firemoth.shaders.fog")

local fogId = "Firemoth Interior"

---@type fogParams
local fogParams = {
    color = tes3vector3.new(0.09, 0.2, 0.15),
    center = tes3vector3.new(),
    radius = tes3vector3.new(),
    density = 60,
}

local function calcInteriorFogParams(marker)
    local root = tes3.game.worldObjectRoot

    local origin = root.worldBoundOrigin
    local radius = root.worldBoundRadius

    fogParams.center.x = origin.x
    fogParams.center.y = origin.y
    fogParams.center.z = marker.position.z

    fogParams.radius.x = radius
    fogParams.radius.y = radius
    fogParams.radius.z = math.deg(marker.orientation.z)

    -- encoded such that 1.04 scale is 4 density
    fogParams.density = (marker.scale - 1.0) * 100
end

local markers = {}

local function getActiveMarker()
    local cell = tes3.player.cell
    for marker in pairs(markers) do
        if marker.cell == cell then
            return marker
        end
    end
end

local function update()
    local marker = getActiveMarker()
    if marker then
        calcInteriorFogParams(marker)
        fog.createOrUpdateFog(fogId, fogParams)
    else
        fog.deleteFog(fogId)
    end
end
event.register(tes3.event.cellChanged, update)

---@param e referenceActivatedEventData
local function onReferenceCreated(e)
    if e.reference.object.id == "fm_fog_layer" then
        markers[e.reference] = true
        update()
    end
end
event.register(tes3.event.referenceActivated, onReferenceCreated)

---@param e referenceDeactivatedEventData|objectInvalidatedEventData
local function onReferenceDeleted(e)
    if markers[e.object or e.reference] then
        markers[e.object or e.reference] = nil
        update()
    end
end
event.register(tes3.event.referenceDeactivated, onReferenceDeleted)
event.register(tes3.event.objectInvalidated, onReferenceDeleted)
