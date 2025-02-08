---@class questGuider.mapInfo
local this = {}

local mcp_mapExpansion = tes3.hasCodePatchFeature(tes3.codePatchFeature.mapExpansionForTamrielRebuilt)
local minCellGridX = mcp_mapExpansion and -51 or -28
local minCellGridY = mcp_mapExpansion and -64 or -28
local maxCellGridX = mcp_mapExpansion and 51 or 28
local maxCellGridY = mcp_mapExpansion and 38 or 28

local worldBounds = {
    minX = minCellGridX,
    maxX = maxCellGridX,
    minY = minCellGridY,
    maxY = maxCellGridY,
    cellResolution = mcp_mapExpansion and 5 or 9,
}

this.uiExpansion = false

this.worldBounds = worldBounds

function this.init()
    if not tes3.isLuaModActive("UI Expansion") then
        this.worldBounds = worldBounds
        return
    end
    local uiexpCommon = include("UI Expansion.common")
    if uiexpCommon and uiexpCommon.config and uiexpCommon.config.components and
            uiexpCommon.config.components.mapPlugin and uiexpCommon.config.mapConfig then
        this.worldBounds = uiexpCommon.config.mapConfig
        this.uiExpansion = true
    else
        this.worldBounds = worldBounds
    end
end

return this