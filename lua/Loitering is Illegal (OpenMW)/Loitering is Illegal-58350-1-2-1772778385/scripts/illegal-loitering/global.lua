local storage = require('openmw.storage')
local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')
local I = require('openmw.interfaces')

local SECTION_NAME = 'illegalLoitering'
local section = storage.globalSection(SECTION_NAME)

local DEFAULT_BOUNTY_PER_HOUR = 10
local DEFAULT_SCAN_RADIUS = 12000
local DEFAULT_GRACE_HOURS = 3

local function ensureDefaults()
    if section:get('bountyPerHour') == nil then
        section:set('bountyPerHour', DEFAULT_BOUNTY_PER_HOUR)
    end
    local scanRadius = section:get('scanRadius')
    if scanRadius == nil then
        section:set('scanRadius', DEFAULT_SCAN_RADIUS)
    end
    if section:get('graceHours') == nil then
        section:set('graceHours', DEFAULT_GRACE_HOURS)
    end
    if section:get('safeCells') == nil then
        section:set('safeCells', {})
    end
end

local function getPlayer()
    return world.players[1]
end

local function getCellInfo(cell)
    if not cell then return nil end
    local name = cell.displayName
    if not name or name == '' then name = cell.name end
    if not name or name == '' then name = cell.id end
    return { id = cell.id, name = name }
end

local function markCurrentCellSafe()
    local player = getPlayer()
    if not player or not player:isValid() then return end

    local cell = player.cell
    if not cell or not cell.id then return end

    local safeCells = section:getCopy('safeCells') or {}
    safeCells[cell.id] = getCellInfo(cell) or true
    section:set('safeCells', safeCells)
    section:set('lastMarkedCell', getCellInfo(cell))
end

local function addBounty(hours, cellId)
    hours = tonumber(hours) or 0
    if hours <= 0 then return end

    local bountyPerHour = section:get('bountyPerHour') or DEFAULT_BOUNTY_PER_HOUR
    local amount = hours * bountyPerHour
    if amount <= 0 then return end

    local player = getPlayer()
    if not player or not player:isValid() then return end

    local current = types.Player.getCrimeLevel(player)
    types.Player.setCrimeLevel(player, current + amount)
    section:set('lastBounty', { amount = amount, hours = hours, cellId = cellId })

    -- Guards normally only force dialogue above iCrimeThreshold.
    -- To make guards confront immediately for loitering, commit a "seen" trespass crime to start pursuit,
    -- then remove the automatic trespass bounty so only the loitering bounty remains.
    local ok, res = pcall(function()
        if not I or not I.Crimes or not I.Crimes.commitCrime then return end
        local out = I.Crimes.commitCrime(player, { type = types.Player.OFFENSE_TYPE.Trespassing })
        if not out or out.wasCrimeSeen ~= true then return end

        local trespassBounty = core.getGMST('iCrimeTresspass')
        if type(trespassBounty) ~= 'number' then return end

        local after = types.Player.getCrimeLevel(player)
        types.Player.setCrimeLevel(player, math.max(0, after - trespassBounty))
    end)
    if not ok then
        -- Ignore errors; loiter bounty still applies.
        return
    end
end

ensureDefaults()

return {
    eventHandlers = {
        illegalLoitering_RequestMarkCurrentCellSafe = function()
            ensureDefaults()
            markCurrentCellSafe()
        end,
        illegalLoitering_RequestResetSafeCells = function()
            ensureDefaults()
            section:set('safeCells', {})
            section:set('lastMarkedCell', nil)
        end,
        illegalLoitering_AddBounty = function(data)
            ensureDefaults()
            if type(data) ~= 'table' then return end
            addBounty(data.hours, data.cellId)
        end,
    },
}
