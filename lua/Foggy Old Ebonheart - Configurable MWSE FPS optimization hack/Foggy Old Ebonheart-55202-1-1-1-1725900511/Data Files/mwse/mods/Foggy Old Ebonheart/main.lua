local prevCell = nil
local viewRangeIncrementSteps = 10
local game = tes3.getGame()

local defaultConfig = {
    viewRangeIncrementSteps = 10,
}

local defaultWhiteList = {
    cells = {
        "Old Ebonheart",
        "Old Ebonheart, Docks"
    }
}

local configPath = "config"
local whitelistPath = "whitelist"

local config = mwse.loadConfig(configPath, defaultConfig)
local whitelist = mwse.loadConfig(whitelistPath, defaultWhiteList)

local function isReducedDrawDistanceCell(cell)
    -- Check if cell.name is whitelisted
    for _, cellName in ipairs(whitelist.cells) do
        if cellName == cell.name then
            return true
        end
    end
end

local function increaseViewRange()
    for i = 1, viewRangeIncrementSteps do
        mge.macros.increaseViewRange()
    end
end

local function decreaseViewRange()
    for i = 1, viewRangeIncrementSteps do
        mge.macros.decreaseViewRange()
    end
end

local function onGameLoaded(e)
    prevCell = tes3.player.cell
    mwse.log("[FOE] viewRangeIncrementSteps: %s", config.viewRangeIncrementSteps)
    for _, cellName in ipairs(whitelist.cells) do
        mwse.log("[FOE] Whitelisted cell: %s", cellName)
    end
    if isReducedDrawDistanceCell(tes3.player.cell) then
        local prevRenderDistance = game.renderDistance
        decreaseViewRange()
        mwse.log("[FOE] player is in designated area, decreased render distance from %s to %s", prevRenderDistance,
            game.renderDistance)
    end
end

local function onCellChanged(e)
    local prevRenderDistance = game.renderDistance
    if (isReducedDrawDistanceCell(e.cell) and (not isReducedDrawDistanceCell(prevCell))) then -- Current cell is Old Ebonheart, previous cell is not
        decreaseViewRange()
        mwse.log("[FOE] Entering designated area, decreased render distance from %s to %s", prevRenderDistance,
            game.renderDistance)
    elseif ((not isReducedDrawDistanceCell(e.cell)) and isReducedDrawDistanceCell(prevCell)) then -- Current cell is not Old Ebonheart, previous cell is
        increaseViewRange()
        mwse.log("[FOE] Leaving designated area, increased render distance from %s to %s", prevRenderDistance,
            game.renderDistance)
    end
    prevCell = e.cell
end

event.register(tes3.event.cellChanged, onCellChanged)
event.register(tes3.event.loaded, onGameLoaded)
