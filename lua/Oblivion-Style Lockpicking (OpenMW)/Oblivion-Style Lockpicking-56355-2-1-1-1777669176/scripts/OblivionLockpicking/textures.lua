local vfs = require("openmw.vfs")
local markup = require("openmw.markup")
local util = require("openmw.util")

local Lockable = require("openmw.types").Lockable
local Door = require("openmw.types").Door
local Container = require("openmw.types").Container

local texturePath = "textures/oblivionlockpicking/"
local overridePath = "textures/oblivionlockpicking/overrides/"
local baseAtlasPath = texturePath .. "base_textures.yaml"

local Element = {
    base = 1,
    cover = 2,
    spring = 3,
    pin = 4,
    pick_1 = 5,
    pick_2 = 6,
    pick_3 = 7,
    pick_4 = 8,
    pick_5 = 9,
    pick_6 = 10,
    probe_1 = 11,
    probe_2 = 12,
    probe_3 = 13,
    probe_4 = 14,
    probe_5 = 15,
}
local function getElementKey(element)
    for k, v in pairs(Element) do
        if v == element then
            return k
        end
    end
    return nil
end

local baseOverride = nil
local atlases = {}
local overrides = {}

local function parseOverrideFile(name)
    local file = vfs.open(name)
    if not file then
        print("ERROR: " .. name .. " not found")
        return
    end
    file:close()
    local data = markup.loadYaml(name)
    return data
end

local function parseAtlas(atlas)
    if not atlas then
        return nil
    end
    local atlasData = {}
    atlasData.name = atlas.name
    atlasData.elements = {}
    for e, element in pairs(atlas.elements) do
        local elementData = {}
        elementData.path = element.path or atlas.path
        elementData.offset = element.offset and util.vector2(element.offset[1], element.offset[2]) or nil
        elementData.size = element.size and util.vector2(element.size[1], element.size[2]) or nil
        elementData.pos = element.pos and util.vector2(element.pos[1], element.pos[2]) or nil
        atlasData.elements[e] = elementData
    end
    return atlasData
end

local function getOverrideFiles()
    overrides = {}
    local overrideFiles = {}

    -- Gather all override files with their priority
    for fileName in vfs.pathsWithPrefix(overridePath) do
        if fileName:sub(-5) == ".yaml" then
            local override = parseOverrideFile(fileName)
            if override then
                local priority = override.priority or 1000
                table.insert(overrideFiles, { fileName = fileName, override = override, priority = priority })
            end
        end
    end

    -- Sort by priority ascending (lower number = higher priority), then alphabetically by filename
    table.sort(overrideFiles, function(a, b)
        if a.priority == b.priority then
            return a.fileName < b.fileName
        end
        return a.priority < b.priority
    end)

    -- Apply atlases: lower priority (higher number) first, so higher priority (lower number) can override
    for i = #overrideFiles, 1, -1 do
        local override = overrideFiles[i].override
        if override.atlases then
            for _, atlas in ipairs(override.atlases) do
                local atlasName = atlas.name
                if atlases[atlasName] then
                    print("NOTICE: Atlas \"" .. atlasName .. "\" already exists, merging")
                else
                    atlases[atlasName] = {}
                end
                local atlasData = parseAtlas(atlas)
                atlases[atlasName].elements = atlases[atlasName].elements or {}
                for e, element in pairs(atlasData.elements) do
                    atlases[atlasName].elements[e] = atlases[atlasName].elements[e] or {}
                    for k, v in pairs(element) do
                        atlases[atlasName].elements[e][k] = v or atlases[atlasName].elements[e][k]
                    end
                end
            end
        end
    end

    -- Apply overrides: higher priority (lower number) first
    for i = 1, #overrideFiles do
        local override = overrideFiles[i].override
        if override.overrides then
            table.insert(overrides, override.overrides)
        end
    end
end

local function getBaseAtlas()
    local atlas = parseOverrideFile(baseAtlasPath)
    if atlas then
        atlases['base'] = parseAtlas(atlas.atlases[1])
        baseOverride = atlas.overrides
    end
end

local function getElement(atlas, element)
    if not atlas or not element then
        return nil
    end
    atlas = atlas or {}
    local baseElementData = atlases['base'].elements[getElementKey(element)] or {}
    local elementData = atlas.elements and atlas.elements[getElementKey(element)] or {}
    local data = {
        texturePath = texturePath .. (elementData.path or baseElementData.path or ''),
        offset = elementData.offset or baseElementData.offset or util.vector2(0, 0),
        size = elementData.size or baseElementData.size or util.vector2(0, 0),
        pos = elementData.pos or baseElementData.pos or util.vector2(0, 0),
    }
    return data
end

local function matchOverride(override, level, objId, recordId, modelId)
    if not override then
        return nil
    end
    level = level or 0
    recordId = recordId or ""
    modelId = modelId or ""
    local atlas = nil
    for _, override in ipairs(override) do
        local criteria = override.criteria
        local valid = true
        if criteria.levelLowerBound and criteria.levelLowerBound > level then
            valid = false
        end
        if criteria.levelUpperBound and criteria.levelUpperBound < level then
            valid = false
        end
        if criteria.randomChance then
            local hash = tonumber(tostring(objId):gsub("0x", ""), 16) or tonumber(objId) or 0
            hash = util.bitAnd(util.bitXor(hash, 0x5bd1e995) * 0x27d4eb2d, 0xFFFFFFFF)
            local rand = (hash % 100) / 100
            if rand > criteria.randomChance then
                valid = false
            end
        end
        if criteria.recordId then
            local match = false
            for _, id in ipairs(criteria.recordId) do
                if id == recordId then
                    match = true
                    break
                end
            end
            if not match then
                valid = false
            end
        end
        if criteria.modelId then
            local match = false
            for _, id in ipairs(criteria.modelId) do
                if id == modelId then
                    match = true
                    break
                end
            end
            if not match then
                valid = false
            end
        end
        if valid then
            atlas = override.atlas
            break
        end
    end

    return atlas
end

local function getOverride(lockable)
    if not lockable or not Lockable.objectIsInstance(lockable) then
        return nil
    end
    local lockLevel = Lockable.getLockLevel(lockable)
    local record = 
        (Door.objectIsInstance(lockable) and Door.records[lockable.recordId]) or
        (Container.objectIsInstance(lockable) and Container.records[lockable.recordId]) or
        nil
    if not record then
        return nil
    end
    local recordId = record.id
    local modelId = record.model

    for _, override in ipairs(overrides) do
        local atlas = matchOverride(override, lockLevel, lockable.id, recordId, modelId)
        if atlas then
            if atlases[atlas] then
                return atlases[atlas]
            else
                print("WARNING: Atlas \"" .. atlas .. "\" not found")
            end
        end
    end
    local atlas = matchOverride(baseOverride, lockLevel, recordId, modelId)
    return atlas
end

local function init()
    getBaseAtlas()
    getOverrideFiles()
end

return {
    init = init,
    getOverride = getOverride,
    getElement = getElement,
    ELEMENT = Element,
}