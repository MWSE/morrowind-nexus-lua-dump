local core = require('openmw.core')

local M = {}

local lastIllegalLevitationCrimeKey = nil
local illegalLevitationOffenseCount = 0

local function getSetting(key, fallback)
    -- Only call this from player context. Do not use it from the global event handler.
    local ok, settings = pcall(require, 'scripts.gravity_enforcement_act.settings')
    if not ok or not settings or not settings.get then
        return fallback
    end

    return settings.get(key, fallback)
end

local function debugPrint(enabled, msg)
    if enabled then
        print('[GravityEnforcementAct] ' .. msg)
    end
end

local function clampNumber(value, fallback, minValue, maxValue)
    if type(value) ~= 'number' then
        value = fallback
    end
    if minValue and value < minValue then
        value = minValue
    end
    if maxValue and value > maxValue then
        value = maxValue
    end
    return value
end

function M.getCellCrimeKey(cellInfo)
    if not cellInfo then
        return nil
    end

    if cellInfo.isExterior then
        return 'exterior:' .. (cellInfo.id ~= '' and cellInfo.id or cellInfo.region or '')
    end

    return 'interior:' .. (cellInfo.id ~= '' and cellInfo.id or cellInfo.name or '')
end

function M.reset(resetEscalation)
    lastIllegalLevitationCrimeKey = nil
    if resetEscalation then
        illegalLevitationOffenseCount = 0
    end
end

function M.onLegalLevitationArea()
    if getSetting('IllegalLevitationCrimeResetOnLegalArea', false) then
        M.reset(true)
    else
        lastIllegalLevitationCrimeKey = nil
    end
end

function M.getCurrentOffenseCount()
    return illegalLevitationOffenseCount
end

function M.calculateBounty()
    local baseBounty = getSetting('IllegalLevitationCrimeBountyGold', nil)
    if baseBounty == nil then
        baseBounty = getSetting('IllegalLevitationBounty', 250) -- legacy fallback
    end
    baseBounty = clampNumber(baseBounty, 250, 0, 10000)

    if getSetting('IllegalLevitationCrimeEscalationEnabled', true) == false then
        return baseBounty
    end

    local repeatBounty = clampNumber(getSetting('IllegalLevitationCrimeRepeatBountyGold', 150), 150, 0, 10000)
    local maxBounty = clampNumber(getSetting('IllegalLevitationCrimeMaxBountyGold', 1000), 1000, 0, 50000)
    local bounty = baseBounty + (illegalLevitationOffenseCount * repeatBounty)

    if maxBounty > 0 then
        bounty = math.min(bounty, maxBounty)
    end

    return bounty
end

function M.commitIllegalLevitation(cellInfo, showCooldownMessage, opts)
    opts = opts or {}
	
	if getSetting('Enabled', true) == false then
		return false
	end	

    if getSetting('IllegalLevitationCrimeEnabled', opts.enabled ~= false) == false then
        return false
    end

    local oncePerCell = getSetting('IllegalLevitationCrimeOncePerCell', true)
    local crimeKey = M.getCellCrimeKey(cellInfo)
    if oncePerCell ~= false and crimeKey and lastIllegalLevitationCrimeKey == crimeKey then
        return false
    end

    lastIllegalLevitationCrimeKey = crimeKey

	illegalLevitationOffenseCount = illegalLevitationOffenseCount + 1

	local bounty = 0
	if illegalLevitationOffenseCount > 1 then
		bounty = M.calculateBounty()
	end

    local showMessage = getSetting('IllegalLevitationCrimeMessageEnabled', true)
    local forceBounty = getSetting('IllegalLevitationCrimeForceBounty', true)
    local debugEnabled = opts.debug == true or getSetting('Debug', false) == true

    core.sendGlobalEvent('GEA_CommitIllegalLevitationCrime', {
        bounty = bounty,
        forceBounty = forceBounty ~= false,
        debug = debugEnabled,
        offenseCount = illegalLevitationOffenseCount,
        cellName = cellInfo and (cellInfo.name ~= '' and cellInfo.name or cellInfo.id) or '',
    })

	if showMessage ~= false and showCooldownMessage then
		if illegalLevitationOffenseCount <= 1 then
			showCooldownMessage(
				'illegal_levitation_warning',
				'You are warned: levitation is forbidden here.',
				2.0
			)
		else
			showCooldownMessage(
				'illegal_levitation_crime',
				string.format('Your illegal levitation has been reported. Bounty added: %d gold.', bounty),
				2.0
			)
		end
	end

    return true
end

function M.onCommitIllegalLevitationCrime(data)
    local world = require('openmw.world')
    local types = require('openmw.types')
    local I = require('openmw.interfaces')

    local player = world.players[1]
    if not player or not player:isValid() then
        return
    end

    if not I.Crimes or not I.Crimes.commitCrime then
        print('[GravityEnforcementAct] Crimes interface is not available; illegal levitation bounty was not applied.')
        return
    end

    local bounty = 250
    if data and type(data.bounty) == 'number' then
        bounty = math.max(0, data.bounty)
    end

    local beforeBounty = 0
    if types.Player and types.Player.getCrimeLevel then
        local okBefore, value = pcall(types.Player.getCrimeLevel, player)
        if okBefore and type(value) == 'number' then
            beforeBounty = value
        end
    end

	local afterBounty = beforeBounty

	if bounty > 0 then
		local forcedBounty = beforeBounty + bounty
		local okSet, err = pcall(types.Player.setCrimeLevel, player, forcedBounty)

		if not okSet then
			print('[GravityEnforcementAct] Failed to apply illegal levitation bounty: ' .. tostring(err))
			return
		end

		afterBounty = forcedBounty
	end

	debugPrint(data and data.debug == true, string.format(
		'Illegal levitation bounty applied. bounty=%s offenseCount=%s before=%s after=%s cell=%s',
		tostring(bounty),
		tostring(data and data.offenseCount or ''),
		tostring(beforeBounty),
		tostring(afterBounty),
		tostring(data and data.cellName or '')
	))
end

return M
