local util = require('openmw.util')
local types = require('openmw.types')

local M = {}
local v3 = util.vector3

function M.lower(s)
    if type(s) ~= 'string' then
        return nil
    end
    return string.lower(s)
end

function M.contains(s, token)
    s = M.lower(s)
    token = M.lower(token)
    return s ~= nil and token ~= nil and string.find(s, token, 1, true) ~= nil
end

function M.containsAny(s, tokens)
    if not s or not tokens then
        return false, nil
    end
    for _, token in ipairs(tokens) do
        if M.contains(s, token) then
            return true, token
        end
    end
    return false, nil
end

local function safeRecord(obj, typeTable)
    local ok, rec = pcall(function()
        return typeTable.record(obj)
    end)
    if ok then
        return rec
    end
    return nil
end

function M.recordForObject(obj)
    if not obj or not obj:isValid() then
        return nil
    end

    if types.Static.objectIsInstance(obj) then
        return safeRecord(obj, types.Static)
    end

    if types.Activator.objectIsInstance(obj) then
        return safeRecord(obj, types.Activator)
    end

    if types.Door.objectIsInstance(obj) then
        return safeRecord(obj, types.Door)
    end

    return nil
end

function M.modelForObject(obj)
    local rec = M.recordForObject(obj)
    if rec and rec.model then
        local model = M.lower(rec.model)
        if model then
            model = string.gsub(model, "\\", "/")
        end
        return model
    end
    return nil
end

function M.idForObject(obj)
    if obj and obj.recordId then
        return M.lower(obj.recordId)
    end
    return nil
end

function M.objectSummary(obj)
    if not obj or not obj:isValid() then
        return '<invalid object>'
    end
    local id = M.idForObject(obj) or '<no record id>'
    local model = M.modelForObject(obj) or '<no model>'
    return 'recordId=' .. id .. ', model=' .. model
end

function M.bboxLooksWalkable(obj, cfg)
    if not cfg.USE_BBOX_FILTER_FOR_FALLBACKS then
        return true, 'bbox filter disabled'
    end

    local ok, box = pcall(function()
        return obj:getBoundingBox()
    end)
    if not ok or not box or not box.halfSize then
        return true, 'no bbox available'
    end

    local sx = math.abs(box.halfSize.x) * 2
    local sy = math.abs(box.halfSize.y) * 2
    local sz = math.abs(box.halfSize.z) * 2
    local length = math.max(sx, sy)
    local width = math.min(sx, sy)

    if length < cfg.MIN_FALLBACK_LENGTH then
        return false, 'too short'
    end
    if width > cfg.MAX_FALLBACK_WIDTH then
        return false, 'too wide'
    end
    if sz > cfg.MAX_FALLBACK_HEIGHT then
        return false, 'too tall'
    end

    return true, 'bbox ok'
end

function M.textureNameMatches(textureName, ropeTextures)
    local tex = M.lower(textureName)
    if not tex then
        return false, nil
    end

    tex = string.gsub(tex, "\\", "/")
    tex = string.gsub(tex, "%.dds$", "")
    tex = string.gsub(tex, "%.tga$", "")
    tex = string.gsub(tex, "%.png$", "")

    if ropeTextures.exact[tex] then
        return true, tex
    end

    for _, token in ipairs(ropeTextures.tokens) do
        if M.contains(tex, token) then
            return true, tex
        end
    end

    return false, nil
end

local function addCardinals(out, r)
    table.insert(out, v3(r, 0, 0))
    table.insert(out, v3(-r, 0, 0))
    table.insert(out, v3(0, r, 0))
    table.insert(out, v3(0, -r, 0))
end

local function addDiagonals(out, r)
    local d = r * 0.70710678
    table.insert(out, v3(d, d, 0))
    table.insert(out, v3(-d, d, 0))
    table.insert(out, v3(d, -d, 0))
    table.insert(out, v3(-d, -d, 0))
end

function M.sampleOffsets(radiiOrRadius)
    local out = { v3(0, 0, 0) }

    if type(radiiOrRadius) == 'table' then
        for _, r in ipairs(radiiOrRadius) do
            r = tonumber(r) or 0
            if r > 0 then
                addCardinals(out, r)
                -- Diagonals are useful near the player, but expensive and overly permissive at the outer ring.
                if r <= 32 then
                    addDiagonals(out, r)
                end
            end
        end
        return out
    end

    local r = radiiOrRadius or 0
    addCardinals(out, r)
    addDiagonals(out, r)
    addCardinals(out, r * 1.7)
    return out
end

return M
