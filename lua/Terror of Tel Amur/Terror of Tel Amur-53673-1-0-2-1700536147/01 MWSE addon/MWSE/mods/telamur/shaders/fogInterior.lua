local fog = require("telamur.shaders.fog")
local cells = require("telamur.utils.cells")

local fogId = "Tel Amur Interior"

local isTelAmurFogCell = cells.isTelAmurFogCell

local BASE_DEPTH = 512
local FOG_COLOUR = tes3vector3.new(0.06, 0.13, 0.35)
local MAX_DISTANCE = 24576

local BLUE = {0.02, 0.123, 0.678}
local VIOLET = {0.432, 0.354, 0.885}
local DENSITY = 14

local DURATION = 0.3
local TOTAL_TIME = 60

local lerpTimer

local fogParams = {
    color = FOG_COLOUR,
    center = tes3vector3.new(),
    radius = tes3vector3.new(MAX_DISTANCE, MAX_DISTANCE, BASE_DEPTH),
    density = DENSITY,
}

local function calcInteriorFogParams(colour)

    local playerPos = tes3.mobilePlayer.position:copy()
    local mistCenter = tes3vector3.new(
        (playerPos.x),
        (playerPos.y),
        0
    )
    fogParams.center = mistCenter
    fogParams.radius = tes3vector3.new(MAX_DISTANCE, MAX_DISTANCE, BASE_DEPTH)
    fogParams.color = colour or FOG_COLOUR
end


local function setBlueVioletColor(currentTime)
    -- Calculate the interpolation factor (t) based on currentTime
    local t = (1 + math.sin(currentTime / TOTAL_TIME * math.pi)) / 2

    debug.log(t)

    -- Use math.lerp() to interpolate between blue and violet
    local lerpedColor = tes3vector3.new(
        math.lerp(BLUE[1], VIOLET[1], t),
        math.lerp(BLUE[2], VIOLET[2], t),
        math.lerp(BLUE[3], VIOLET[3], t)
    )

    -- Set the color of the element using the lerpedColor
    calcInteriorFogParams(lerpedColor)
    fog.createOrUpdateFog(fogId, fogParams)
end

local currentTime = 0.0
-- Call this function in our timer callback or loop
local function updateColor()
    setBlueVioletColor(currentTime)
    currentTime = (currentTime + 1) % TOTAL_TIME
end

local function update()
    local cell = tes3.getPlayerCell()
    local isAvailable = cell and isTelAmurFogCell(cell)
    if isAvailable then
        calcInteriorFogParams(nil)
        fog.createOrUpdateFog(fogId, fogParams)
        lerpTimer = timer.start({
            duration = DURATION,
            iterations = -1,
            callback = function()
                updateColor()
            end
        })
    else
        fog.deleteFog(fogId)
        if (lerpTimer) and not (lerpTimer.state == timer.expired) then
            lerpTimer:cancel()
            lerpTimer = nil
        end
    end
end

event.register(tes3.event.cellChanged, update)
