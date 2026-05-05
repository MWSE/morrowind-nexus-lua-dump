local menu = require("openmw.menu")
local core = require("openmw.core")
local async = require("openmw.async")


local tempSaveName = "__advWMap__temp__save__"


local function getTempSaves()
    local out = {}
    local saves = menu.getSaves(menu.getCurrentSaveDir())
    for name, dt in pairs(saves) do
        if name:find(tempSaveName, 1, true) then
            table.insert(out, name)
        end
    end
    return out
end

local function deleteTempSaves()
    local saves = getTempSaves()
    for _, name in pairs(saves) do
        menu.deleteGame(menu.getCurrentSaveDir(), name)
    end
end



return{
    eventHandlers = {
        ["AdvWMap:startDataRebuilding"] = function (data)
            menu.saveGame(tempSaveName, tempSaveName)
            async:newUnsavableSimulationTimer(0.001, function ()
                core.sendGlobalEvent("AdvWMap:rebuildMapData", data)
            end)
        end,
        ["AdvWMap:finishDataRebuilding"] = function (dt)
            local saves = getTempSaves()
            if next(saves) then
                menu.loadGame(menu.getCurrentSaveDir(), saves[1])
                async:newUnsavableSimulationTimer(0.001, function ()
                    deleteTempSaves()
                    if dt and dt.options and dt.plId then
                        core.sendGlobalEvent("AdvWMap:processMapDataOptions", dt)
                    end
                end)
            end
        end,
    }
}