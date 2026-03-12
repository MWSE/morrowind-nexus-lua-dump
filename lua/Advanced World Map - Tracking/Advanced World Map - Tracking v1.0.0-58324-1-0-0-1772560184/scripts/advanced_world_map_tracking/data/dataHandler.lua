local commonData = require("scripts.advanced_world_map_tracking.common")
local tableLib = require("scripts.advanced_world_map_tracking.utils.table")

local version = 0

local this = {}

---@type table<string, table<string, advWMap_tracking.markerData>> by groupId or recordId, by id
this.markers = {}

---@type table<string, advWMap_tracking.markerTemplateData> by template id
this.templates = {}

this.version = 0



function this.load(dataTable)
    if not dataTable then return end
    this.markers = dataTable[commonData.mapMarkersKey] or {}
    this.templates = dataTable[commonData.mapTemplatesKey] or {}
    this.version = dataTable[commonData.mapDataVersionKey] or version
end


function this.save(dataTable)
    ---@type table<string, advWMap_tracking.markerTemplateData>
    local templates = tableLib.deepcopy(this.templates)
    for id, data in pairs(templates) do
        if data.invalid or data.temp ~= false or data.short then
            templates[id] = nil
        end
    end

    ---@type table<string, table<string, advWMap_tracking.markerData>>
    local markers = tableLib.deepcopy(this.markers)

    for groupId, cellData in pairs(markers) do
        for id, data in pairs(cellData) do
            if not data.template or
                    (type(data.template) == "string" and not templates[data.template]) or
                    data.temp ~= false or data.short or data.objects or data.invalid or data.isVisibleFn or
                    data.objValidateFn then
                (markers[groupId] or {})[id] = nil
            end
        end
    end

    dataTable[commonData.mapMarkersKey] = markers
    dataTable[commonData.mapTemplatesKey] = templates
    dataTable[commonData.mapDataVersionKey] = version
end


---@param id string
---@param groupId string
---@return advWMap_tracking.markerData?
function this.getMarker(id, groupId)
    if not id or not groupId then return end

    local cellDt = this.markers[groupId]
    if not cellDt then return end
    return cellDt[id]
end


---@param id string
---@param groupId string
---@return advWMap_tracking.markerData[]?
function this.getMarkers(id, groupId)
    if not id or not groupId then return end

    local markerData = this.getMarker(id, groupId)
    if not markerData then return end

    local out = {markerData}
    if markerData.records then
        for _, objId in pairs(markerData.records) do
            if this.markers[objId] and this.markers[objId][id] then
                table.insert(out, this.markers[objId][id])
            end
        end
    end
    if markerData.positions then
        local worldGr = markerData.zoomOut and commonData.worldCellLabel or nil
        for _, posData in pairs(markerData.positions) do
            local grId = posData.id or worldGr or commonData.getCellIdByPos(posData.pos)
            if grId and this.markers[grId] and this.markers[grId][id] then
                table.insert(out, this.markers[grId][id])
            end
        end
    end
    if markerData.objects then
        for _, obj in pairs(markerData.objects) do
            if obj:isValid() then
                local dt = this.getMarker(obj.id, groupId)
                if dt then
                    table.insert(out, dt)
                end
            end
        end
    end
    if markerData.types then
        for _, typeId in pairs(markerData.types) do
            if this.markers[typeId] and this.markers[typeId][id] then
                table.insert(out, this.markers[typeId][id])
            end
        end
    end

    return out
end


---@param id string
---@return advWMap_tracking.markerTemplateData?
function this.getTemplate(id)
    if not id then return end
    return this.templates[id]
end


---@param id string
---@param data advWMap_tracking.markerTemplateData
function this.addTemplate(id, data)
    if not id then return end
    local template = this.templates[id]
    if template then
        tableLib.clear(template)
        tableLib.copy(data, template)
    else
        this.templates[id] = data
    end
end


---@param id string
---@param groupId string
---@param data advWMap_tracking.markerData
function this.addMarker(id, groupId, data)
    if not id or not groupId then return end

    this.markers[groupId] = this.markers[groupId] or {}
    if this.markers[groupId][id] then
        this.markers[groupId][id].invalid = true
    end
    this.markers[groupId][id] = data
end


---@param id string
---@return boolean
function this.removeTemplate(id)
    if not id then return false end
    local template = this.templates[id]
    if not template then return false end

    template.invalid = true
    this.templates[id] = nil

    return true
end


---@param id string
---@param groupId string
---@return boolean?
function this.removeMarker(id, groupId)
    local marker = this.getMarker(id, groupId)
    if not marker then return false end

    if marker.positions then
        local mk = this.getMarker(id, commonData.positionsLabel)
        if mk then
            local worldGr = mk.zoomOut and commonData.worldCellLabel or nil
            for _, posData in pairs(mk.positions) do
                local grId = posData.id or worldGr or commonData.getCellIdByPos(posData.pos)
                if grId and this.markers[grId] and this.markers[grId][id] then
                    this.markers[grId][id].invalid = true
                    this.markers[grId][id] = nil
                end
            end

            mk.invalid = true
            this.markers[commonData.positionsLabel][id] = nil
        end
    end

    if marker.records then
        local mk = this.getMarker(id, commonData.recordsLabel)
        if mk then
            for _, objId in pairs(marker.records) do
                if this.markers[objId] and this.markers[objId][id] then
                    this.markers[objId][id].invalid = true
                    this.markers[objId][id] = nil
                end
            end

            mk.invalid = true
            this.markers[commonData.recordsLabel][id] = nil
        end
    end

    if marker.objects then
        local mk = this.getMarker(id, commonData.objectsLabel)

        if mk then
            for _, obj in pairs(marker.objects) do
                if obj:isValid() then
                    local mrk = this.getMarker(id, obj.id)
                    if mrk then
                        mrk.invalid = true
                        this.markers[obj.id][id] = nil
                    end
                end
            end

            mk.invalid = true
            this.markers[commonData.objectsLabel][id] = nil
        end
    end

    if marker.types then
        local mk = this.getMarker(id, commonData.typesLabel)

        if mk then
            for _, typeId in pairs(marker.types) do
                if this.markers[typeId] and this.markers[typeId][id] then
                    this.markers[typeId][id].invalid = true
                    this.markers[typeId][id] = nil
                end
            end

            mk.invalid = true
            this.markers[commonData.typesLabel][id] = nil
        end
    end

    marker.invalid = true
    this.markers[groupId][id] = nil
    return true
end


---@param groupId string
---@return fun(): string, advWMap_tracking.markerData iterator marker id, marker data
function this.iterMarkerGroup(groupId)
    local function iterator()
        local group = this.markers[groupId]
        for id, data in pairs(group or {}) do
            if not data.invalid then
                coroutine.yield(id, data)
            else
                group[id] = nil
            end
        end
    end
    return coroutine.wrap(iterator)
end


---@param markerData advWMap_tracking.markerData
---@return advWMap_tracking.markerTemplateData?
function this.getMarkerTemplate(markerData)
    if not markerData.template then return nil end

    if type(markerData.template) == "string" then
        return this.getTemplate(markerData.template) ---@diagnostic disable-line: param-type-mismatch
    else
        return markerData.template ---@diagnostic disable-line: return-type-mismatch
    end
end


function this.removeAll()
    for id, data in pairs(this.templates) do
        data.invalid = true
        this.templates[id] = nil
    end
    for id, groupData in pairs(this.markers) do
        for _, data in pairs(groupData) do
            if type(data.template) ~= "string" then
                data.template.invalid = true
            end
        end
        this.markers[id] = nil
    end
end


return this