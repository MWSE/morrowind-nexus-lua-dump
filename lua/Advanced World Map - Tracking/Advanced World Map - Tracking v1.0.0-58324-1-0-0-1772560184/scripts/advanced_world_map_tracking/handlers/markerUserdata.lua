local ui = require("openmw.ui")
local util = require("openmw.util")
local playerRef = require("openmw.self")
local core = require("openmw.core")

local common = require("scripts.advanced_world_map_tracking.common")
local config = require("scripts.advanced_world_map_tracking.config.config")
local mapData = require("scripts.advanced_world_map_tracking.data.dataHandler")
local tableLib = require("scripts.advanced_world_map_tracking.utils.table")


---@class activeMarkers.markerUserdata
local this = {}
this.__index = this

local markerType = {
    pos = 1,
    object = 2,
}


---@param markerData advWMap_tracking.markerData
---@param template advWMap_tracking.markerTemplateData
---@return boolean
function this:addMarkerData(markerData, template)
    local id = markerData.id or ""
    if self.data[id] then return false end

    self.data[id] = {
        [1] = markerData,
        [2] = template,
    }
    self.count = self.count + 1

    self.parent.addToRegisteredMarkers(self.cellId, markerData.id, self.obj and markerType.object or markerType.pos, self.marker)

    if self.objId then
        if not self.activeData.objectMarkers[self.objId] then
            self.activeData.objectMarkers[self.objId] = self.marker
        end
    elseif self.posHash then
        if not self.activeData.posMarkers[self.posHash] then
            self.activeData.posMarkers[self.posHash] = self.marker
        end
    end

    self:updateMarker()

    return true
end


function this:remove()
    for id, _ in self:dataIterator() do
        self.parent.removeFromRegisteredMarkers(self.activeData, id, self.marker)
    end

    if self.objId then
        local objMarker = self.activeData.objectMarkers[self.objId]
        if objMarker then
            self.activeData.objectMarkers[self.objId] = nil
        end
    else
        local markerId = self.posHash
        self.activeData.posMarkers[markerId or ""] = nil

        if self.grid then
            local tb = self.zoomOut and self.activeData.gridOut or self.activeData.grid
            for _, gridId in pairs(self.grid) do
                tb[gridId] = nil
            end
        end
    end

    self.marker:destroy()

    self.activeData.activeMarkers[self.marker._id] = nil
    self.activeData.visibleMarkers[self.marker._id] = nil
end


function this:getTopVisibleTemplate()
    local topData
    local topPriority = -math.huge
    for _, dt in pairs(self.data) do
        if dt[3] and (dt[1].priority or 0) > topPriority then
            topData = dt
            topPriority = dt[1].priority or 0
        end
    end
    return topData and topData[2] or nil
end


local distance2D = common.distance2D


---@return boolean
function this:isDataVisible(data, tm)
    ---@type advWMap_tracking.markerData
    local markerData = data[1]
    ---@type advWMap_tracking.markerTemplateData
    local markerTemplate = data[2]

    local res = markerTemplate.visible ~= false

    if res then
        if markerData.isVisibleFn then
            local r = markerData.isVisibleFn(markerData, markerTemplate, self.obj and self.obj.object)
            if r == nil then
                res = data.lf or false
            else
                res = r
                data.lf = r
            end
        end
        if res and markerData.alive ~= nil then
            res = res and self.obj ~= nil and markerData.alive == self.obj:isAlive()
        end
        if res and markerData.distance ~= nil then
            if self.obj then
                local plCell = playerRef.cell
                local objCell = self.obj.object.cell
                local isInSameSpace = plCell.isExterior and objCell.isExterior or plCell.id == objCell.id
                res = res and isInSameSpace and markerData.distance >= distance2D(self.obj.position, playerRef.position)
                self.lastVisResT = res

            elseif self.posHash then
                local plCell = playerRef.cell
                local posCellId = self.cellId
                local isInSameSpace = plCell.isExterior and posCellId == common.worldCellLabel or plCell.id == posCellId
                res = res and isInSameSpace and markerData.distance >= distance2D(self.lastPos, playerRef.position)
            end
        end
        if res and markerData.item and self.obj then
            tm = tm or core.getRealTime()

            if self.itemUTm < tm then
                self.itemUTm = tm + self.itUBTm
                self.itemLastVis = self.obj:hasItem(markerData.item, true)
            end

            res = res and self.itemLastVis
        end
    end

    data[3] = res

    return res
end


---@param template advWMap_tracking.markerTemplateData
local function getABTexturePath(template, pos)
    if not template.pathA and not template.pathB then return template.path end

    local playerZ = playerRef.position.z
    local markerZ = pos.z
    local path

    if markerZ > playerZ + config.data.tracking.aboveBelowHeight then
        path = template.pathA
    elseif markerZ < playerZ - config.data.tracking.aboveBelowHeight then
        path = template.pathB
    end

    return path or template.path or "white"
end


---@return boolean
function this:updateMarker()
    if self.obj and not self.obj:isValid() then
        self:remove()
        return false
    end

    local isVisible = false
    for id, dt in pairs(self.data) do
        local mkd = dt[1]
        local mkt = dt[2]

        if mkd.invalid or mkt.invalid then
            self.parent.removeFromRegisteredMarkers(self.activeData, mkd.id, self.marker)
            self:removeMarkerData(id)
        elseif mkd.active and self.obj and not self.obj:isActive() or
                mkd.activeEx and self.obj and not self.obj:isActive() and self.obj.cell and self.obj.cell.isExterior then
            self.parent.removeFromRegisteredMarkers(self.activeData, mkd.id, self.marker)
            self:removeMarkerData(id)
        else
            local visible = self:isDataVisible(dt)
            isVisible = isVisible or visible
        end
    end

    if not self:hasData() then
        self:remove()
        return false
    end

    if isVisible and self.obj then
        isVisible = self.obj:isVisible()
    end

    local template = self:getTopVisibleTemplate()
    self.topTemplate = template

    if self.obj then
        self.lastPos = self.obj.position
    end

    local texture
    if template then
        if self.obj and not self.zoomOut and self.obj:isActive() then
            local path = getABTexturePath(template, self.lastPos)
            texture = ui.texture{ path = path }
        else
            texture = ui.texture{ path = template.path }
        end
    end

    ---@diagnostic disable-next-line: missing-fields
    self.marker:updateParams{
        texture = texture,
        size = template and template.size or util.vector2(10, 10),
        color = template and template.color or common.defaultColor,
        anchor = template and template.anchor or util.vector2(0.5, 0.5),
        pos = self.obj and self.obj.position or nil, ---@diagnostic disable-line: assign-type-mismatch
        visible = template ~= nil and isVisible,
    }
    self.marker:restoreLayout()

    if isVisible then
        self.activeData.visibleMarkers[self.marker._id] = self
    else
        self.activeData.visibleMarkers[self.marker._id] = nil
    end

    return true
end


function this:updateMarkerABTexture()
    if not self.topTemplate then return end

    local path = getABTexturePath(self.topTemplate, self.lastPos)

    local texture = ui.texture{ path = path }
    self.marker:setTexture(texture)
end


function this:updateMarkerPos()
    if self.obj and not self.obj:isValid() then
        self:remove()
        return false
    end

    if self.obj then
        if (self.obj.position - self.lastPos):length() > 2 then
            self.marker:setPosition(self.obj.position)
            self.lastPos = self.obj.position
        end

        if not self.zoomOut and self.obj:isActive() then
            self:updateMarkerABTexture()
        end
    end
    return true
end


function this:updateMarkerVisibility(tm)
    if self.visUTm > tm then
        return
    end

    if self.obj and not self.obj:isValid() then
        self:remove()
        return false
    end

    local topTemplate = self:getTopVisibleTemplate()
    if topTemplate ~= self.topTemplate then
        self.visUTm = tm + self.rndTm
        return self:updateMarker()
    end

    local isVisible = false
    for _, dt in pairs(self.data) do
        local mkd = dt[1]
        local mkt = dt[2]

        if mkd.invalid or mkt.invalid or
                mkd.active and self.obj and not self.obj:isActive() or
                mkd.activeEx and self.obj and not self.obj:isActive() and self.obj.cell and self.obj.cell.isExterior then
            self.visUTm = tm + self.rndTm
            return self:updateMarker()
        end
        isVisible = isVisible or self:isDataVisible(dt, tm)
    end

    if isVisible and self.obj then
        isVisible = self.obj:isVisible()
    end

    self.marker:setVisibility(isVisible)

    if isVisible then
        self.activeData.visibleMarkers[self.marker._id] = self
    else
        self.activeData.visibleMarkers[self.marker._id] = nil
    end

    self.visUTm = tm + self.rndTm

    return true
end


function this:hasData()
    return self.count > 0
end


function this:hasInvalid()
    for _, v in pairs(self.data) do
        if v[1].invalid or v[2].invalid then
            return true
        end
    end
    return false
end


---@param id string
---@return boolean
function this:removeMarkerData(id)
    if not self.data[id] then return false end

    self.data[id] = nil
    self.count = self.count - 1
    if self.funcs and self.funcs[id] then
        self.funcs[id] = nil
        self.funcsCount = self.funcsCount - 1

        if not next(self.funcs) then
            self.funcs = nil
        end
    end

    self.parent.removeFromRegisteredMarkers(self.activeData, id, self.marker)

    return true
end


function this:triggerOnClick(btn)
    for _, mkd, mkt in self:dataIterator() do

        if mkt.onClick then
            if type(mkt.onClick) == "string" then
                mkd = tableLib.copy(mkd)
                mkd.isVisibleFn = nil
                mkd.objValidateFn = nil
                playerRef:sendEvent(mkt.onClick, {
                    button = btn,
                    marker = mkd,
                    template = mkt,
                    object = self.obj and self.obj.object,
                })
            elseif type(mkt.onClick) == "function" then
                mkt.onClick{
                    button = btn,
                    marker = mkd,
                    template = mkt,
                    object = self.obj and self.obj.object,
                }
            end
        end
    end
end


---@return fun(): (string, advWMap_tracking.markerData, advWMap_tracking.markerTemplateData)
function this:dataIterator()
    local function iter(t, k)
        local v
        k, v = next(t, k)

        if k == nil then return nil end

        return k, v[1], v[2]
    end

    return iter, self.data, nil ---@diagnostic disable-line: redundant-return-value
end


---@return {[1]: advWMap_tracking.markerData, [2]: advWMap_tracking.markerTemplateData}[]
function this:getSortedData()
    local data = {}
    for _, dt in pairs(self.data) do
        table.insert(data, dt)
    end

    table.sort(data, function (a, b)
        return (a[1].priority or 0) > (b[1].priority or 0)
    end)

    return data
end


return this