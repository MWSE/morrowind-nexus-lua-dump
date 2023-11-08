local this = {
    enabled = false,
}

local drawDistance
local aboveWaterFogStart
local aboveWaterFogEnd

local nearStaticEnd
local farStaticEnd
local veryFarStaticEnd

local farStaticMinSize
local veryFarStaticMinSize

function this.setEnabled(enabled)
    if enabled == this.enabled then
        return
    end
    mwse.log("[Colossus] toggleDistantLandConfig(enabled=%s)", enabled)

    local c = mge.distantLandRenderConfig
    if enabled then
        drawDistance, c.drawDistance = c.drawDistance, 12.0
        aboveWaterFogStart, c.aboveWaterFogStart = c.aboveWaterFogStart, 3.3
        aboveWaterFogEnd, c.aboveWaterFogEnd = c.aboveWaterFogEnd, 12.0
        nearStaticEnd, c.nearStaticEnd = c.nearStaticEnd, 4.0
        farStaticEnd, c.farStaticEnd = c.farStaticEnd, 8.0
        veryFarStaticEnd, c.veryFarStaticEnd = c.veryFarStaticEnd, 11.8
        farStaticMinSize, c.farStaticMinSize = c.farStaticMinSize, 600.00
        veryFarStaticMinSize, c.veryFarStaticMinSize = c.veryFarStaticMinSize, 800.00
    else
        c.drawDistance = drawDistance or c.drawDistance
        c.aboveWaterFogStart = aboveWaterFogStart or c.aboveWaterFogStart
        c.aboveWaterFogEnd = aboveWaterFogEnd or c.aboveWaterFogEnd
        c.nearStaticEnd = nearStaticEnd or c.nearStaticEnd
        c.farStaticEnd = farStaticEnd or c.farStaticEnd
        c.veryFarStaticEnd = veryFarStaticEnd or c.veryFarStaticEnd
        c.farStaticMinSize = farStaticMinSize or c.farStaticMinSize
        c.veryFarStaticMinSize = veryFarStaticMinSize or c.veryFarStaticMinSize
    end

    this.enabled = enabled
end

return this
