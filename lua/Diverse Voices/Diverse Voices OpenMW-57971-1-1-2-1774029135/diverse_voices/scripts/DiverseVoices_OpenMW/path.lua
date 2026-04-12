local vfs = require('openmw.vfs')

local M = {}
local replacementCache = {}

local function normalize(path)
    return tostring(path):gsub('/', '\\')
end

local function cacheGet(key)
    local cached = replacementCache[key]
    if cached ~= nil then
        return cached or nil
    end
    return nil, false
end

local function cacheSet(key, value)
    replacementCache[key] = value or false
    return value
end

function M.buildVariantPath(originalPath, variant)
    if not originalPath or originalPath == '' or not variant or variant == '' then
        return nil
    end

    local normalized = normalize(originalPath)
    local dir, file = normalized:match('^(.*)\\([^\\]+)$')
    if not dir or not file then
        return nil
    end

    return dir .. '\\' .. variant .. '\\' .. file
end

function M.resolveVariantPath(originalPath, variant)
    if not originalPath or originalPath == '' or not variant or variant == '' then
        return nil
    end

    local normalized = normalize(originalPath)
    local cacheKey = normalized .. '|' .. variant
    local cached = replacementCache[cacheKey]
    if cached ~= nil then
        return cached or nil
    end

    local replacement = M.buildVariantPath(normalized, variant)
    if replacement and vfs.fileExists(replacement) then
        replacementCache[cacheKey] = replacement
        return replacement
    end

    replacementCache[cacheKey] = false
    return nil
end

function M.buildDefaultPath(originalPath)
    return M.buildVariantPath(originalPath, 'default')
end

function M.resolveDefaultPath(originalPath)
    return M.resolveVariantPath(originalPath, 'default')
end

function M.buildVoiceTypePath(originalPath, voiceType)
    return M.buildVariantPath(originalPath, voiceType)
end

function M.resolveVoiceTypePath(originalPath, voiceType)
    return M.resolveVariantPath(originalPath, voiceType)
end

return M
