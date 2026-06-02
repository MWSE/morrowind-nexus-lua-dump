local world = require('openmw.world')
local types = require('openmw.types')

local shared = require('scripts.fire_shared')

local PLAYER_SCRIPT = 'scripts/fire_damage.lua'

local EXEMPT = {}
for i = 1, #shared.FIRE_EXEMPTIONS do
    EXEMPT[shared.FIRE_EXEMPTIONS[i]:lower()] = true
end

local KW = {}
for i = 1, #shared.FIRE_KEYWORDS do
    KW[i] = shared.FIRE_KEYWORDS[i]:lower()
end
local KW_N = #KW

local recordIsFire = {}

local function classifyRecord(idLower)
    if EXEMPT[idLower] then return false end
    for i = 1, KW_N do
        if idLower:find(KW[i], 1, true) then return true end
    end
    return false
end

-- localized type checks
local Static_isInstance    = types.Static.objectIsInstance
local Light_isInstance     = types.Light.objectIsInstance

local function isFireType(obj)
    return Static_isInstance(obj)
        or Light_isInstance(obj)
end

local function cellMatches(fcell, desc)
    if not fcell or not desc then return false end
    if (fcell.isExterior and true or false) ~= desc.isExterior then return false end
    if desc.isExterior then
        return (fcell.gridX or 0) == desc.gridX
           and (fcell.gridY or 0) == desc.gridY
    end
    return (fcell.name or '') == desc.name
end

local activeFires = {}    -- [obj.id] = obj

local function ensurePlayerScript(player)
    if not player:hasScript(PLAYER_SCRIPT) then
        player:addScript(PLAYER_SCRIPT)
    end
end

local function onObjectActive(obj)
    if not isFireType(obj) then return end

    local id = obj.recordId
    if not id then return end

    local verdict = recordIsFire[id]
    if verdict == nil then
        verdict = classifyRecord(id:lower())
        recordIsFire[id] = verdict
    end
    if not verdict then return end

    activeFires[obj.id] = obj

    local player = world.players[1]
    if player and player:isValid() then
        ensurePlayerScript(player)
        player:sendEvent('AddFire', obj)
    end
end

local function onRequestFireScan(data)
    local player = world.players[1]
    if not player or not player:isValid() then return end
    ensurePlayerScript(player)

    local desc = data and data.cell
    local list, n = {}, 0

    for fid, fobj in pairs(activeFires) do
        local keep = false
        if fobj:isValid() and fobj.count > 0 then
            if cellMatches(fobj.cell, desc) then
                keep = true
            end
        end
        if keep then
            n = n + 1
            list[n] = fobj
        else
            activeFires[fid] = nil
        end
    end

    player:sendEvent('UpdateFireList', list)
end

return {
    engineHandlers = {
        onObjectActive = onObjectActive,
    },
    eventHandlers = {
        RequestFireScan = onRequestFireScan,
    },
}