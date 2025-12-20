local ui = require("openmw.ui")
local util = require("openmw.util")
local core = require("openmw.core")
local playerRef = require("openmw.self")

local config = require("scripts.advanced_world_map.config.configLib")
local mapDataHandler = require("scripts.advanced_world_map.mapDataHandler")

local eventSys = require("scripts.advanced_world_map.eventSys")


local this = {}


local nameLayout

---@param menu advancedWorldMap.ui.menu.map
function this.updateLabel(menu)
    if not nameLayout or not menu or not menu.mapWidget then return end
    local mapWidget = menu.mapWidget
    local text
    if mapWidget.cellId then
        local cellName = mapDataHandler.cellNameById[mapWidget.cellId]
        if cellName then
            text = string.format(" %s ", cellName)
        end
    elseif playerRef.cell.isExterior and menu.centerOnPlayer then
        local cellName = mapDataHandler.cellNameById[playerRef.cell.id]
        if cellName then
            text = string.format(" %s ", cellName)
        end
    end
    nameLayout.props.text = text or ""
end


---@param menu advancedWorldMap.ui.menu.map
local function create(menu)

    nameLayout = {
        type = ui.TYPE.Text,
        props = {
            text = "",
            textSize = menu.headerHeight - 6,
            anchor = util.vector2(0.5, 0.5),
            textColor = config.data.ui.defaultColor,
        },
    }
    this.updateLabel(menu)


    menu:addWidget{
        id = "AdvancedWorldMap:CellName",
        layout = nameLayout,
        priority = -100,
        showWhenMenuInactive = true,
    }

end


eventSys.registerHandler(eventSys.EVENT.onMapShown, function (e)
    this.updateLabel(e.menu)
end)

eventSys.registerHandler(eventSys.EVENT.onMenuOpened, function (e)
    create(e.menu)
end, -1000)


return this