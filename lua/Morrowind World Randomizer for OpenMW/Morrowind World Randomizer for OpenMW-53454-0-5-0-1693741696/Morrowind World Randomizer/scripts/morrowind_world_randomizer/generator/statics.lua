local types = require('openmw.types')
local world = require('openmw.world')
local log = require("scripts.morrowind_world_randomizer.utils.log")
local generatorData = require("scripts.morrowind_world_randomizer.generator.data")

local this = {}

---@class mwr.staticParameters
---@field radius number|nil

---@class mwr.staticsData
---@field objects table<string, mwr.staticParameters>
---@field groups table<table<string>>

local function checkRequirements(id, object)
    if object.model ~= "" and not generatorData.forbiddenModels[object.model:lower()] and not generatorData.forbiddenIds[id] then
        return true
    end
    return false
end

---@return mwr.staticsData
function this.generateTreeData()
    ---@type mwr.staticsData
    local out = {objects = {}, groups = {}}

    local data = {}
    for  _, object in pairs(types.Static.records) do
        local id = object.id:lower()
        if (id:find("tree") or id:find("parasol")) and checkRequirements(id, object) then

            local str = ((id:gsub("[_ ]", "") or ""):match(".+%d+") or ""):match("%a+")
            if str then
                if not data[str] then data[str] = {} end
                table.insert(data[str], id)
            end
        end
    end
    for _, gr in pairs(data) do
        local ids = {}
        for _, id in pairs(gr) do
            out.objects[id] = {}
            table.insert(ids, id)
        end
        if #ids > 0 then
            table.insert(out.groups, ids)
        end
    end

    return out
end

---@return mwr.staticsData
function this.generateFloraData()
    ---@type mwr.staticsData
    local out = {objects = {}, groups = {}}

    local data = {}
    for  _, object in pairs(types.Static.records) do
        local id = object.id:lower()
        if checkRequirements(id, object) and (id:find("grass") or id:find("bush") or id:find("flora")) and
                not (id:find("tree") or id:find("log") or id:find("menhir") or id:find("root") or id:find("parasol") or id:find("rock") or
                id:find("plane") or id:find("caveentr")) then

            local str = ((id:gsub("[_ ]", "") or ""):match(".+%d+") or ""):match("%a+")
            if str then
                if not data[str] then data[str] = {} end
                table.insert(data[str], id)
            end
        end
    end
    for _, gr in pairs(data) do
        local ids = {}
        for _, id in pairs(gr) do
            out.objects[id] = {}
            table.insert(ids, id)
        end
        if #ids > 0 then
            table.insert(out.groups, ids)
        end
    end

    return out
end

---@return mwr.staticsData
function this.generateRockData()
    ---@type mwr.staticsData
    local out = {objects = {}, groups = {}}

    local data = {}
    for  _, object in pairs(types.Static.records) do
        local id = object.id:lower()
        if (id:find("rock") or id:find("menhir")) and not (id:find("grp") or id:find("cliff")) and checkRequirements(id, object) then

            local str = ((id:gsub("[_ ]", "") or ""):match(".+%d+") or ""):match("%a+")
            if str then
                if not data[str] then data[str] = {} end
                table.insert(data[str], id)
            end
        end
    end
    for _, gr in pairs(data) do
        local ids = {}
        for _, id in pairs(gr) do
            out.objects[id] = {}
            table.insert(ids, id)
        end
        if #ids > 0 then
            table.insert(out.groups, ids)
        end
    end

    return out
end

---@return mwr.staticsData
function this.rebuildRocksTreesData(data)
    ---@type mwr.staticsData
    local out = {groups = {}, objects = {}}
    if not data then return out end
    local existing = {}
    for _, record in pairs(types.Static.records) do
        existing[record.id:lower()] = true
    end
    local grpArr
    if data.RocksGroups then
        grpArr = data.RocksGroups
    elseif data.TreesGroups then
        grpArr = data.TreesGroups
    else
        grpArr = {}
    end
    for i, dt in pairs(grpArr) do
        local group = {}
        for _, objId in pairs(dt.Items) do
            local id = objId:lower()
            if existing[id] then
                table.insert(group, objId)
                out.objects[id] = {}
            end
        end
        if #group > 0 then
            table.insert(out.groups, group)
        end
    end
    return out
end

return this