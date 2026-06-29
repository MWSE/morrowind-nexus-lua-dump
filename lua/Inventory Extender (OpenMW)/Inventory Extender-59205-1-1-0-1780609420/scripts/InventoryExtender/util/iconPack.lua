local storage = require('openmw.storage')
local vfs = require('openmw.vfs')

local hasUi, ui = pcall(require, 'openmw.ui')

local windowSettings = storage.playerSection('Settings/InventoryExtender/2_WindowOptions')

local IconPack = {}

local ICON_ROOT = 'icons/inventoryextender'
local DEFAULT_PACK = 'Base'
local ICON_PACK_KEY = 's_IconPack'

local function capitalize(str)
    return (str:gsub('(%a)([%w_%-]*)', function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

local function normalizeRelativePath(path)
    return (path or ''):gsub('^[/\\]+', '')
end

function IconPack.getAvailablePacks()
    local packs = {}
    local seen = {}

    for path in vfs.pathsWithPrefix(ICON_ROOT) do
        local relativePath = path:sub(#ICON_ROOT + 2)
        local packName = relativePath:match('([^/\\]+)')
        if packName and not seen[packName] then
            seen[packName] = true
            table.insert(packs, capitalize(packName))
        end
    end

    if not seen[DEFAULT_PACK] then
        table.insert(packs, 1, DEFAULT_PACK)
    end

    table.sort(packs, function(a, b)
        if a == DEFAULT_PACK then return true end
        if b == DEFAULT_PACK then return false end
        return a:lower() < b:lower()
    end)

    return packs
end

function IconPack.getCurrentPack()
    local currentPack = windowSettings:get(ICON_PACK_KEY)
    if currentPack and currentPack ~= '' then
        return currentPack
    end
    return DEFAULT_PACK
end

function IconPack.getPath(relativePath, iconPackName)
    local path = normalizeRelativePath(relativePath)
    local currentPack = iconPackName or IconPack.getCurrentPack()
    local packedPath = string.format('%s/%s/%s', ICON_ROOT, currentPack, path)

    if currentPack ~= DEFAULT_PACK and not vfs.fileExists(packedPath) then
        return string.format('%s/%s/%s', ICON_ROOT, DEFAULT_PACK, path)
    end

    return packedPath
end

function IconPack.getTexture(relativePath, iconPackName)
    if not hasUi then
        return nil
    end
    return ui.texture { path = IconPack.getPath(relativePath, iconPackName) }
end

return IconPack