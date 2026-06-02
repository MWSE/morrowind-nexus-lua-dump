local self    = require('openmw.self')
local core    = require('openmw.core')
local storage = require('openmw.storage')
local async   = require('openmw.async')
local camera  = require('openmw.camera')
local ui      = require('openmw.ui')
local nearby  = require('openmw.nearby')
local util    = require('openmw.util')
local time    = require('openmw_aux.time')
local I       = require('openmw.interfaces')

local shared                = require('scripts.npcschedule_shared')
local DEFAULTS              = shared.DEFAULTS
local SAFE_KEYWORDS         = shared.SAFE_KEYWORDS
local CITY_CELLS            = shared.CITY_CELLS
local GRID_CELLS            = shared.GRID_CELLS
local BLACKLISTED_INTERIORS = shared.BLACKLISTED_INTERIORS
local MOURNHOLD_INTERIORS   = shared.MOURNHOLD_INTERIORS

-- Constants
local CELL_RATE = 1.0 * time.second
local WAIST     = util.vector3(0, 0, 60)

-- UI modes where teleporting an NPC out from under the player would be jarring
local DIALOGUE_MODES = {
    Dialogue        = true,
    Barter          = true,
    MerchantRepair  = true,
    SpellBuying     = true,
    SpellCreation   = true,
    Enchanting      = true,
}


-- settings
local section = storage.playerSection('SettingsNPCSchedule')

local function getSetting(key)
    local val = section:get(key)
    if val == nil then return DEFAULTS[key] end
    return val
end

local logEnabled = false
local function log(...)
    if logEnabled then print('[NPCSch P]', ...) end
end

local function broadcastSettings()
    local data = {}
    for k in pairs(DEFAULTS) do data[k] = getSetting(k) end
    core.sendGlobalEvent('NPCSch_SettingsUpdated', data)
end

section:subscribe(async:callback(function()
    logEnabled = getSetting('ENABLE_LOGS')
    broadcastSettings()
end))


-- cell classification
local function isOutdoorCell(cell)
    if not cell then return false end
    if cell.isExterior then return true end
    local n = cell.name
    return n and n ~= '' and MOURNHOLD_INTERIORS[n:lower()] == true
end

local function isCityCell(cell)
    if not cell then return false end
    local n = cell.name
    if n and n ~= '' then return CITY_CELLS[n:lower()] == true end
    if cell.isExterior and GRID_CELLS then
        return GRID_CELLS[cell.gridX .. ',' .. cell.gridY] == true
    end
    return false
end

local function isSafeCell(cell)
    if not cell then return false end
    local n = cell.name
    if not n or n == '' then return false end
    local lo = n:lower()
    if BLACKLISTED_INTERIORS[lo] then return false end
    for _, kw in ipairs(SAFE_KEYWORDS) do
        if lo:find(kw, 1, true) then return true end
    end
    return false
end


-- line-of-sight
local function isOnScreen(actor)
    if not actor or not actor:isValid() then return false end
    local ts = camera.worldToViewportVector(actor.position)
    if not ts then return false end
    local ss = ui:screenSize()
    return ts.x > 0 and ts.x < ss.x and ts.y > 0 and ts.y < ss.y
end

local function isBlockedByWall(actor)
    if not actor or not actor:isValid() then return true end
    local r = nearby.castRay(
        self.position + WAIST, actor.position + WAIST,
        { collisionType = nearby.COLLISION_TYPE.World, ignore = { self.object, actor } }
    )
    return r.hit
end

local function isInDialogueWith(actor)
    local mode = I.UI.getMode()
    if not DIALOGUE_MODES[mode] then return false end
    return (self.position - actor.position):length() < 300
end

-- State
local lastCell     = nil
local settingsSent = false
local cellTimer    = 0

-- Cell-transition handling
local function notifyCellEntry(cur)
    -- first cell after start/load
    core.sendGlobalEvent(
        isOutdoorCell(cur) and 'NPCSch_PlayerEnteredExterior' or 'NPCSch_PlayerEnteredInterior',
        { cellName = cur.name or '' }
    )
end

local function notifyCellTransition(prev, cur)
    local prevExt = isOutdoorCell(prev)
    local curExt  = isOutdoorCell(cur)
    local whitelist = getSetting('CITY_WHITELIST')

    -- night: entered exterior city
    if not prevExt and curExt then
        if not whitelist or isCityCell(cur) then
            core.sendGlobalEvent('NPCSch_PlayerEnteredExterior', {})
            log('Entered exterior')
        end
    end

    -- night: exterior -> interior
    if prevExt and not curExt then
        core.sendGlobalEvent('NPCSch_PlayerLeftExterior', {})
        core.sendGlobalEvent('NPCSch_PlayerEnteredInterior', { cellName = cur.name or '' })
        log('Entered interior:', cur.name or '?')
    end

    -- interior -> interior
    if not prevExt and not curExt then
        core.sendGlobalEvent('NPCSch_PlayerEnteredInterior', { cellName = cur.name or '' })
        log('Moved to interior:', cur.name or '?')
    end

    -- morning: exited safe place to exterior
    if not prevExt and isSafeCell(prev) and curExt then
        core.sendGlobalEvent('NPCSch_MorningExitSafe', {})
        log('Exited safe place to exterior')
    end
end

-- Engine handlers
local function onUpdate(dt)
    if not settingsSent then
        settingsSent = true
        logEnabled = getSetting('ENABLE_LOGS')
        broadcastSettings()
    end

    cellTimer = cellTimer + dt
    if cellTimer < CELL_RATE then return end
    cellTimer = cellTimer - CELL_RATE  -- preserve remainder

    local cur = self.cell
    if cur == lastCell then return end

    local prev = lastCell
    lastCell   = cur
    if not cur then return end

    if prev then
        notifyCellTransition(prev, cur)
    else
        notifyCellEntry(cur)
    end
end


-- EVENT HANDLERS
-- global asks player to check whether the player can see an NPC.
-- reply with whether the NPC can be safely teleported away.
local function onCheckLOS(data)
    local actor = data.actor
    if not actor or not actor:isValid() then return end

    local canTeleport
    if isInDialogueWith(actor) then
        canTeleport = false
        log('LOS check: NPC is dialogue target, blocking teleport')
    elseif isOnScreen(actor) and not isBlockedByWall(actor) then
        canTeleport = false  -- player sees NPC
    else
        canTeleport = true   -- player not looking, or wall blocks
    end

    actor:sendEvent('NPCSch_LOSDone', { canTeleport = canTeleport })
    log('LOS check:', actor.recordId, 'canTP:', tostring(canTeleport))
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        NPCSch_CheckLOS = onCheckLOS,
    },
}