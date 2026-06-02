local self = require('openmw.self')
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local types = require('openmw.types')

local lower, sub, tostring, ipairs = string.lower, string.sub, tostring, ipairs

local DETACH_PERIOD = 0.001
local DEBUG_MESSAGES = false
local CHECK_NGARDE_LOADED = true
local ONLY_BTP_ACTORS = true

local EXTERIOR_MIN_X, EXTERIOR_MAX_X = -109, -104
local EXTERIOR_MIN_Y, EXTERIOR_MAX_Y = 39, 43

local BTP_INTERIOR_CELLS = {
    ["the frozen crypt of nhar'zekhaal"] = true,
    ["the frozen crypt of nhar'zekhaal, chamber of the lich"] = true,
    ['morasil skarr'] = true,
    ['vvardaguul'] = true,
    ['vvardaguul, inner shrine'] = true,
}

local BTP_ACTOR_IDS = {
    ['sch_fjomo_np_boss'] = true,
}

local BTP_ACTOR_PREFIXES = {
    'sch_',
}

local NGARDE_LOADED = (not CHECK_NGARDE_LOADED)
    or core.contentFiles.has('ngarde.omwaddon')
    or core.contentFiles.has('ngarde.omwscripts')

local timer = 0
local lastDebugState = nil

local function norm(s)
    return lower(tostring(s or ''))
end

local function debugMessage(msg)
    if DEBUG_MESSAGES then
        self:sendEvent('ShowMessage', { message = tostring(msg) })
    end
end

local function inExteriorRange(cell)
    if not cell or not cell.isExterior then return false end

    local x, y = cell.gridX, cell.gridY
    if x == nil or y == nil then return false end

    return x >= EXTERIOR_MIN_X and x <= EXTERIOR_MAX_X
        and y >= EXTERIOR_MIN_Y and y <= EXTERIOR_MAX_Y
end

local function inInteriorList(cell)
    return cell and BTP_INTERIOR_CELLS[norm(cell.name)] == true
end

local function playerInBtpCell()
    local cell = self.cell
    return inExteriorRange(cell) or inInteriorList(cell)
end

local function isBtpActor(actor)
    local rid = norm(actor.recordId)

    if BTP_ACTOR_IDS[rid] then return true end

    for _, prefix in ipairs(BTP_ACTOR_PREFIXES) do
        if sub(rid, 1, #prefix) == prefix then
            return true
        end
    end

    return false
end

local function shouldDetach(actor)
    if not actor or actor == self or not actor:isValid() then return false end
    if actor.type ~= types.NPC and actor.type ~= types.Creature then return false end
    if ONLY_BTP_ACTORS and not isBtpActor(actor) then return false end
    return true
end

local function detachNearbyActors()
    local count = 0

    for _, actor in ipairs(nearby.actors) do
        if shouldDetach(actor) then
            actor:sendEvent('ngarde_prepareDetach')
            count = count + 1
        end
    end

    return count
end

local function onUpdate(dt)
    timer = timer - dt
    if timer > 0 then return end
    timer = DETACH_PERIOD

    if not NGARDE_LOADED then return end

    local inBtp = playerInBtpCell()

    if DEBUG_MESSAGES and inBtp ~= lastDebugState then
        lastDebugState = inBtp
        debugMessage("BtP N'Garde suppressor: " .. tostring(inBtp))
    end

    if not inBtp then return end

    local count = detachNearbyActors()

    if DEBUG_MESSAGES and count > 0 then
        debugMessage("Detached N'Garde actors: " .. tostring(count))
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
}