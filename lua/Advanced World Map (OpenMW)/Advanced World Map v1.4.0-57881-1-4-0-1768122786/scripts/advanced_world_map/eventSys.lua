local log = require("scripts.advanced_world_map.utils.log")
local tableLib = require("scripts.advanced_world_map.utils.table")

local this = {}


this.EVENT = {
    onMenuOpened = "onMenuOpened",
    onMenuClosed = "onMenuClosed",
    onUpdate = "onUpdate",
    onWorldMapTextureInitialize = "onWorldMapTextureInitialize",
    onMapInitialized = "onMapInitialized",
    onMapShown = "onMapShown",
    onMapClosed = "onMapClosed",
    onCellMarkersCreate = "onCellMarkersCreate",
    onMarkerClick = "onMarkerClick",
    onMarkerClicked = "onMarkerClicked",
    onMarkerTooltipShow = "onMarkerTooltipShow",
    onMarkerTooltipShowed = "onMarkerTooltipShowed",
    onMapElementInitialized = "onMapElementInitialized",
    onMapElementCreated = "onMapElementCreated",
    onMapElementRemoved = "onMapElementRemoved",
    onMousePress = "onMousePress",
    onMouseRelease = "onMouseRelease",
    onFocusLoss = "onFocusLoss",
    onMouseMove = "onMouseMove",
    onRightMouseMenu = "onRightMouseMenu",
    onResized = "onResized",
    onZoomed = "onZoomed",
    onZoomMarkersUpdated = "onZoomMarkersUpdated",
    onGroundTexturesPlace = "onGroundTexturesPlace",
    onSearch = "onSearch",
    onFastTravel = "onFastTravel",
    onFastTravelResolve = "onFastTravelResolve",
    onFastTravelResolved = "onFastTravelResolved",
}


this.handlers = {}

---@param eventId string
---@param handlerFunc fun(e : table)
---@overload fun(eventId : "onMenuOpened", handlerFunc: fun(e : {menu : advancedWorldMap.ui.menu.map}) : (boolean?), priority : number?)
---@overload fun(eventId : "onMenuClosed", handlerFunc: fun(e : {menu : advancedWorldMap.ui.menu.map}) : (boolean?), priority : number?)
---@overload fun(eventId : "onUpdate", handlerFunc: fun(e : {menu : advancedWorldMap.ui.menu.map}) : (boolean?), priority : number?)
---@overload fun(eventId : "onWorldMapTextureInitialize", handlerFunc: fun(e : {mapWidget : advancedWorldMap.ui.mapWidgetMeta, mapInfo : advancedWorldMap.mapImageInfo?, texture : string|any?}) : (boolean?), priority : number?)
---@overload fun(eventId : "onMapInitialized", handlerFunc: fun(e : {menu : advancedWorldMap.ui.menu.map, mapWidget : advancedWorldMap.ui.mapWidgetMeta, cellId : string?}) : (boolean?), priority : number?)
---@overload fun(eventId : "onMapShown", handlerFunc: fun(e : {menu : advancedWorldMap.ui.menu.map, mapWidget : advancedWorldMap.ui.mapWidgetMeta, cellId : string?}) : (boolean?), priority : number?)
---@overload fun(eventId : "onMapClosed", handlerFunc: fun(e : {menu : advancedWorldMap.ui.menu.map, mapWidget : advancedWorldMap.ui.mapWidgetMeta, cellId : string?}) : (boolean?), priority : number?)
---@overload fun(eventId : "onCellMarkersCreate", handlerFunc: fun(e : {mapWidget : advancedWorldMap.ui.mapWidgetMeta, cellId : string?}) : (boolean?, boolean?), priority : number?)
---@overload fun(eventId : "onMarkerClick", handlerFunc: fun(e : {marker : advancedWorldMap.ui.mapElementMeta}) : (boolean?, boolean?), priority : number?)
---@overload fun(eventId : "onMarkerClicked", handlerFunc: fun(e : {marker : advancedWorldMap.ui.mapElementMeta}) : (boolean?), priority : number?)
---@overload fun(eventId : "onMarkerTooltipShow", handlerFunc: fun(e : {marker : advancedWorldMap.ui.mapElementMeta, content : any}) : (boolean?, boolean?), priority : number?)
---@overload fun(eventId : "onMarkerTooltipShowed", handlerFunc: fun(e : {marker : advancedWorldMap.ui.mapElementMeta, content : any, tooltip : any}) : (boolean?), priority : number?)
---@overload fun(eventId : "onMapElementInitialized", handlerFunc: fun(e : {mapWidget : advancedWorldMap.ui.mapWidgetMeta, marker : advancedWorldMap.ui.mapElementMeta}) : (boolean?), priority : number?)
---@overload fun(eventId : "onMapElementCreated", handlerFunc: fun(e : {mapWidget : advancedWorldMap.ui.mapWidgetMeta, marker : advancedWorldMap.ui.mapElementMeta}) : (boolean?), priority : number?)
---@overload fun(eventId : "onMapElementRemoved", handlerFunc: fun(e : {mapWidget : advancedWorldMap.ui.mapWidgetMeta, marker : advancedWorldMap.ui.mapElementMeta}) : (boolean?), priority : number?)
---@overload fun(eventId : "onMousePress", handlerFunc: fun(e : {marker : advancedWorldMap.ui.mapElementMeta?, offset : any, position : any, button : integer}) : (boolean?, boolean?), priority : number?)
---@overload fun(eventId : "onMouseRelease", handlerFunc: fun(e : {marker : advancedWorldMap.ui.mapElementMeta?, offset : any, position : any, button : integer}) : (boolean?, boolean?), priority : number?)
---@overload fun(eventId : "onFocusLoss", handlerFunc: fun(e : {marker : advancedWorldMap.ui.mapElementMeta?}) : (boolean?, boolean?), priority : number?)
---@overload fun(eventId : "onMouseMove", handlerFunc: fun(e : {marker : advancedWorldMap.ui.mapElementMeta?, offset : any, position : any}) : (boolean?, boolean?), priority : number?)
---@overload fun(eventId : "onRightMouseMenu", handlerFunc: fun(e : {mapWidget : advancedWorldMap.ui.mapWidgetMeta, marker : advancedWorldMap.ui.mapElementMeta, content : any, relPos : any}) : (boolean?), priority : number?)
---@overload fun(eventId : "onResized", handlerFunc: fun(e : {menu : advancedWorldMap.ui.menu.map, size : any, mapWidgetSize : any}) : (boolean?), priority : number?)
---@overload fun(eventId : "onZoomed", handlerFunc: fun(e : {mapWidget : advancedWorldMap.ui.mapWidgetMeta, zoom : number}) : (boolean?), priority : number?)
---@overload fun(eventId : "onZoomMarkersUpdated", handlerFunc: fun(e : {mapWidget : advancedWorldMap.ui.mapWidgetMeta, region : any}) : (boolean?), priority : number?)
---@overload fun(eventId : "onGroundTexturesPlace", handlerFunc: fun(e : {mapWidget : advancedWorldMap.ui.mapWidgetMeta, region : any}) : (boolean?), priority : number?)
---@overload fun(eventId : "onSearch", handlerFunc: fun(e : {results : any[], filter : string, params : any}) : (boolean?), priority : number?)
---@overload fun(eventId : "onFastTravel", handlerFunc: fun(e : {position : any, cellId : string?}) : (boolean?, boolean?), priority : number?)
---@overload fun(eventId : "onFastTravelResolve", handlerFunc: fun(e : {cost : number, message : string, position : any, cell : any, rotation : any, followers : any[]}) : (boolean?, boolean?), priority : number?)
---@overload fun(eventId : "onFastTravelResolved", handlerFunc: fun(e : {cost : number, message : string, position : any, cell : any, rotation : any, followers : any[]?}) : (boolean?), priority : number?)
function this.registerHandler(eventId, handlerFunc, priority)
    if type(handlerFunc) ~= "function" then return end
    this.handlers[eventId] = this.handlers[eventId] or {}
    this.handlers[eventId][handlerFunc] = {handlerFunc, priority or 0}
end


---@param eventId string
---@param handlerFunc fun(e : table)
function this.unregisterHandler(eventId, handlerFunc)
    this.handlers[eventId] = this.handlers[eventId] or {}
    this.handlers[eventId][handlerFunc] = nil
end


---@param eventId string
---@return boolean
function this.isContainsHandler(eventId)
    return this.handlers[eventId] and next(this.handlers[eventId]) and true or false
end


---@param eventId string
---@return boolean? stopped
function this.triggerEvent(eventId, e)
    local handlerData = tableLib.values(this.handlers[eventId] or {}, function (a, b)
        return a[2] > b[2]
    end)

    local block = false
    for _, hData in ipairs(handlerData) do
        local ss, cl, bl = pcall(hData[1], e or {})
        if not ss then
            log("\nerror in \""..eventId.."\" callback:", cl)
            goto continue
        end
        block = bl or block

        if cl then
            break
        end

        ::continue::
    end

    return block
end

return this