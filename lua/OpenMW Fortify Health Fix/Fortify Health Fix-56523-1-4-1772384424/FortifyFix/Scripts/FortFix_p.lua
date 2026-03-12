local core = require('openmw.core')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
local I = require("openmw.interfaces")
local async = require('openmw.async')
local MOD_NAME = "FortifyFix"
local playerSection = storage.playerSection("SettingsPlayer" .. MOD_NAME)
local storedValues = storage.playerSection("storedValues" .. MOD_NAME)
storedValues:setLifeTime(storage.LIFE_TIME.GameSession)
local Player = require('openmw.types').Player
local Actor = require('openmw.types').Actor
local activeSpells = Actor.activeSpells(self)
local activeEffects = Actor.activeEffects(self)
local dynamic = {health = types.Actor.stats.dynamic.health(self), fatigue = types.Actor.stats.dynamic.fatigue(self), magicka = types.Actor.stats.dynamic.magicka(self)}
local dispelling = false

local fortifyToStat = {
	fortifyhealth = "health",
	fortifyfatigue = "fatigue",
	fortifymagicka = "magicka",
}

-- Pre-allocated, refreshed from activeEffects each frame
local bonuses = { health = 0, magicka = 0, fatigue = 0 }

-- Cache: spellId -> false (no fortify), 1 (fortify, not dispellable), 2 (fortify + dispellable spell)
local spellInfoCache = {}

local function getSpellInfo(spell)
	local id = spell.id
	local cached = spellInfoCache[id]
	if cached ~= nil then return cached end
	local result = false
	local record = core.magic.spells.records[id]
	if record then
		for _, effect in pairs(record.effects) do
			if fortifyToStat[effect.id] then
				result = record.type == core.magic.SPELL_TYPE.Spell and 2 or 1
				break
			end
		end
	else
		local source = types.Potion.records[id]
		if not source then
			-- Enchanted item (equipped)
			if spell.item then
				local enchantId = spell.item.type.record(spell.item).enchant or ""
				source = core.magic.enchantments.records[enchantId]
			end
			-- Scroll (item may already be consumed)
			if not source then
				local bookRecord = types.Book.records[id]
				if bookRecord then
					local enchantId = bookRecord.enchant or ""
					source = core.magic.enchantments.records[enchantId]
				end
			end
		end
		if source then
			for _, effect in pairs(source.effects) do
				if fortifyToStat[effect.id] then
					result = 1 -- potions/enchantments are not dispellable
					break
				end
			end
		end
	end
	spellInfoCache[id] = result
	return result
end

local function dbg(...)
	if true then
		print(...)
	end
end

local settingsTemplate = {
	key = "SettingsPlayer" .. MOD_NAME,
	l10n = "none",
	name = "",
	page = MOD_NAME,
	description = "",
	permanentStorage = true,
	settings = {
		{
			key = "healthFortifyBase",
			name = "Fortify Max Health",
			default = false,
			renderer = "checkbox",
			description = "EXPERIMENTAL!! might permanently change your values\nDO !!NOT!! UNINSTALL THE MOD WITH THIS SETTING ENABLED !!!\nREINSTALLING THE MOD WON'T FIX PREVIOUS MISTAKES!",
		},
		{
			key = "healthRestore",
			name = "Restored Health Per Buffed Minute",
			default = 300,
			argument = {
				min = 0,
				max = 99999999999,
			},
			renderer = "number",
			description = "The percentage of the fortify effect that gets restored after it runs out\nCalculated value will never exceed 100%\n(Set to 0 to disable)",
		},
		{
			key = "fatigueRestore",
			name = "Restored Fatigue Per Buffed Minute",
			default = 300,
			argument = {
				min = 0,
				max = 99999999999,
			},
			renderer = "number",
			description = "The percentage of the fortify effect that gets restored after it runs out\nCalculated value will never exceed 100%\n(Set to 0 to disable)",
		},
		{
			key = "magickaRestore",
			name = "Restored Magicka Per Buffed Minute",
			default = 300,
			argument = {
				min = 0,
				max = 99999999999,
			},
			renderer = "number",
			description = "The percentage of the fortify effect that gets restored after it runs out\nCalculated value will never exceed 100%\n(Set to 0 to disable)",
		},
	}
}

I.Settings.registerPage {
	key = MOD_NAME,
	l10n = "none",
	name = "Fortify Fix",
	description = ""
}

I.Settings.registerGroup(settingsTemplate)

-- Cache settings into S_ prefixed globals
local function readAllSettings()
	for _, entry in pairs(settingsTemplate.settings) do
		local value = playerSection:get(entry.key)
		if value == nil then
			value = entry.default
		end
		_G["S_"..entry.key] = value
	end
end

readAllSettings()
playerSection:subscribe(async:callback(function(_, setting)
	local value = playerSection:get(setting)
	if value == nil then
		for _, entry in pairs(settingsTemplate.settings) do
			if entry.key == setting then
				value = entry.default
				break
			end
		end
	end
	_G["S_"..setting] = value
end))

-- Reads fortify magnitudes from activeEffects into the pre-allocated bonuses table.
-- Returns true if any fortify effect is active.
local function refreshBonuses()
	bonuses.health = activeEffects:getEffect("fortifyhealth").magnitude or 0
	bonuses.fatigue = activeEffects:getEffect("fortifyfatigue").magnitude or 0
	bonuses.magicka = activeEffects:getEffect("fortifymagicka").magnitude or 0
	return bonuses.health ~= 0 or bonuses.fatigue ~= 0 or bonuses.magicka ~= 0
end

-- Shared restore logic for both dispel and natural expiry
local function applyFortifyRestore(stat, magnitude, duration, bonus)
	local restorePct = _G["S_"..stat.."Restore"]
	local cap
	if _G["S_"..stat.."FortifyBase"] then
		cap = dynamic[stat].base
	else
		cap = dynamic[stat].base + bonus
	end
	dynamic[stat].current = math.max(1 + magnitude, math.min(
		cap,
		dynamic[stat].current + magnitude * math.min(1, duration / 60 * restorePct / 100)
	))
end


I.AnimationController.addTextKeyHandler('', function(groupname, key)
	if groupname == "spellcast" and key == "self start" then
		local spell = Player.getSelectedSpell(self)
		if not spell then return end
		for a, effect in pairs(spell.effects) do
			if effect.id == "dispel" and effect.magnitudeMin >= 100 then
				dispelling = true
			end
		end
	elseif groupname == "spellcast" and key == "self stop" then
		dispelling = false
	end
end)

I.SkillProgression.addSkillUsedHandler(function(skillId, params)
	if not (dispelling and skillId == "mysticism") then return end
	if not refreshBonuses() then return end
	
	for a, b in pairs(activeSpells) do
		if getSpellInfo(b) == 2 then
			for c, d in pairs(b.effects) do
				local remStat = fortifyToStat[d.id]
				if remStat and d.duration and bonuses[remStat] and _G["S_"..remStat.."Restore"] ~= 0 then
					applyFortifyRestore(remStat, d.magnitudeThisFrame, d.duration, bonuses[remStat])
					activeSpells:remove(b.activeSpellId)
					dbg("dispelled fortify "..math.floor(d.magnitudeThisFrame * math.min(1, d.duration / 60 * _G["S_"..remStat.."Restore"] / 100)).." ("..d.magnitudeThisFrame..") "..remStat.." on self")
				end
			end
		end
	end
end)

local nextExpiryCheck = 0

function onFrame()
	local hasFortify = refreshBonuses()
	
	-- Only iterate activeSpells if a fortify effect is actually present
	if hasFortify then
		local now = core.getSimulationTime()
		if now >= nextExpiryCheck then
			local remId = nil
			local remMagnitude = nil
			local remStat = nil
			local remDuration = nil
			local nearestExpiry = math.huge
			for a, b in pairs(activeSpells) do
				if getSpellInfo(b) then
					for c, d in pairs(b.effects) do
						local stat = fortifyToStat[d.id]
						if stat and d.duration and _G["S_"..stat.."Restore"] ~= 0 then
							if d.durationLeft < 0.2 then
								remId = b.activeSpellId
								remMagnitude = d.magnitudeThisFrame
								remStat = stat
								remDuration = d.duration
							elseif d.durationLeft < nearestExpiry then
								nearestExpiry = d.durationLeft
							end
						end
					end
				end
			end
			if remId then
				applyFortifyRestore(remStat, remMagnitude, remDuration, bonuses[remStat])
				dbg("fortify "..remStat.." ran out, +"..remMagnitude.." "..remStat)
				activeSpells:remove(remId)
				bonuses[remStat] = bonuses[remStat] - remMagnitude
				nextExpiryCheck = 0 -- re-check immediately in case multiple expire at once
			else
				nextExpiryCheck = now + math.max(0, nearestExpiry - 2)
			end
		end
	else
		nextExpiryCheck = 0
	end
	
	for a, b in pairs(bonuses) do
		if _G["S_"..a.."FortifyBase"] then
			if buffCache[a] ~= b then
				dynamic[a].base = dynamic[a].base + b - buffCache[a]
				buffCache[a] = b
			end
		else
			if buffCache[a] > 0 then
				dynamic[a].base = dynamic[a].base - buffCache[a]
				buffCache[a] = 0
			end
		end
	end
end

local function onInit()
	buffCache = {health = 0, fatigue = 0, magicka = 0}
	return {buffCache = {health = 0, fatigue = 0, magicka = 0}}
end
local function onLoad(data)
	if not data then
		print("no data")
	elseif not data.buffCache then
		print("no buffCache")
	end
	buffCache = data and data.buffCache or {health = 0, fatigue = 0, magicka = 0}
end

local function onSave()
	return {buffCache = buffCache}
end


return {
	engineHandlers = {
		onFrame = onFrame,
		onLoad = onLoad,
		onSave = onSave,
		onInit = onInit,
	}
}