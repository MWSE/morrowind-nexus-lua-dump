local self = require('openmw.self')
local core = require('openmw.core')
local interfaces = require('openmw.interfaces')
local achievements = require('scripts.omw_achievements.achievements.achievements')

local frameCount = 0

local sk00maUtils = require('scripts.omw_achievements.utils.sk00maUtils')

local function getCell()

    --- Check for "visit_all" achievements type
    local macData = interfaces.storageUtils.getStorage("counters")
    local visitedCells = macData:getCopy("visitedCells")
    local cellName = string.lower(self.object.cell.name)

    if sk00maUtils.not_contains(visitedCells, cellName) then
        table.insert(visitedCells, cellName)
        print('Added new cell to visitedCells: ' .. cellName)
        macData:set("visitedCells", visitedCells)

        for i = 1, #achievements do
            if achievements[i].type == "visit_all" then
                local cellTable = achievements[i].cells
                if sk00maUtils.search(visitedCells, cellTable) then
                    self.object:sendEvent('gettingAchievement', {
                        id = achievements[i].id,
                        icon = achievements[i].icon,
                        bgColor = achievements[i].bgColor,
                        name = achievements[i].name,
                        description = achievements[i].description
                    })
                end
            end
        end
    end
end

local function onFrame()
    frameCount = frameCount + 1
    if frameCount > 10 then
        getCell()
    end
end

return {
    engineHandlers = {
        onFrame = onFrame
    }
}