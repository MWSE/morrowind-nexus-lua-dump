local cfg = require('scripts.slyropes.config')
local common = require('scripts.slyropes.common')
local known = require('scripts.slyropes.known_rope_ids')

local M = {}

function M.isRopeObject(obj)
    if not obj or not obj:isValid() then
        return false, 'invalid'
    end

    local id = common.idForObject(obj)
    if id and known.ids[id] then
        return true, 'known record id: ' .. id
    end

    if not cfg.RECORD_ENABLE_NAME_FALLBACKS then
        return false, 'not known id'
    end

    local idMatch, idToken = common.containsAny(id, known.nameTokens)
    if idMatch then
        local ok, why = common.bboxLooksWalkable(obj, cfg)
        if ok then
            return true, 'record token: ' .. idToken
        end
        return false, 'record token rejected by bbox: ' .. why
    end

    local model = common.modelForObject(obj)
    local modelMatch, modelToken = common.containsAny(model, known.nameTokens)
    if modelMatch then
        local ok, why = common.bboxLooksWalkable(obj, cfg)
        if ok then
            return true, 'model token: ' .. modelToken
        end
        return false, 'model token rejected by bbox: ' .. why
    end

    return false, 'no record/model match'
end

return M
