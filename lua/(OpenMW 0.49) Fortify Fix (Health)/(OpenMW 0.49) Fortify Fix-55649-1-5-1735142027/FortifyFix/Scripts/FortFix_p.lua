local core = require('openmw.core')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
local I = require("openmw.interfaces")
local input = require('openmw.input')
local async = require('openmw.async')
local animation = require('openmw.animation')
local MOD_NAME = "FortifyFix"
local playerSection = storage.playerSection("SettingsPlayer" .. MOD_NAME)
local storedValues = storage.playerSection("storedValues" .. MOD_NAME)
storedValues:setLifeTime(storage.LIFE_TIME.GameSession)
local UI = require('openmw.interfaces').UI
local Player = require('openmw.types').Player
local Actor = require('openmw.types').Actor
local dynamic = types.Actor.stats.dynamic
local dispelling = false

local function dbg(...)
	if true then
		print(...)
	end
end

I.Settings.registerPage {
	key = MOD_NAME,
	l10n = MOD_NAME,
	name = "Fortify Fix",
	description = ""
}

I.Settings.registerGroup {
	key = "SettingsPlayer" .. MOD_NAME,
	l10n = MOD_NAME,
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
			key = "healthRestore", -- "restoreHealth"
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




I.AnimationController.addTextKeyHandler('', function(groupname, key)
	if groupname == "spellcast" and key == "self start" then
		local spell = Player.getSelectedSpell(self)
		for a,effect in pairs(spell.effects) do
			if effect.id == "dispel" and effect.magnitudeMin >= 100 then
				dispelling = true
				--dbg("started dispelling")
			end
		end
	elseif groupname == "spellcast" and key == "self stop" then
		dispelling = false
		--dbg("stopped dispelling")
	end
end)

I.SkillProgression.addSkillUsedHandler(function(skillId, params)
	--if  playerSection:get("percentagePerMinute") == 0 then
	--	return
	--end
	if dispelling and skillId == "mysticism" then
		local bonuses={
			health = 0,
			magicka = 0,
			fatigue = 0
		}
		for a,b in pairs(bonuses) do
			if playerSection:get(a.."Restore") == 0 then
				bonuses[a] = nil
			end
		end
		for a,b in pairs(Actor.activeSpells(self)) do
			for c,d in pairs(b.effects) do
				if d.id == "fortifyhealth" or d.id == "fortifyfatigue" or d.id == "fortifymagicka" then
					local stat = d.id:sub(8,-1)
					if bonuses[stat] then
						bonuses[stat] = bonuses[stat]+d.magnitudeThisFrame
					end
				end
			end
		end
		for a,b in pairs(Actor.activeSpells(self)) do
			for c,d in pairs(b.effects) do
				if d.duration and (d.id == "fortifyhealth" or d.id == "fortifyfatigue" or d.id == "fortifymagicka") then
					local spell = core.magic.spells.records[b.id]
					if spell ~= nil and spell.type == core.magic.SPELL_TYPE.Spell then
						local remStat = d.id:sub(8,-1)
						if bonuses[remStat] then
							if playerSection:get(remStat.."FortifyBase") then
								dynamic[remStat](self).current = math.max(1+d.magnitudeThisFrame,math.min(
									dynamic[remStat](self).base,
									dynamic[remStat](self).current + d.magnitudeThisFrame * math.min(1, d.duration / 60 * playerSection:get(remStat.."Restore") / 100)
								))
							else
								dynamic[remStat](self).current = math.max(1+d.magnitudeThisFrame,math.min(
									dynamic[remStat](self).base + bonuses[remStat],
									dynamic[remStat](self).current + d.magnitudeThisFrame * math.min(1, d.duration / 60 * playerSection:get(remStat.."Restore") / 100)
								))
							end
							--dynamic[remStat](self).current = math.max(1+d.magnitudeThisFrame, math.min(
							--	dynamic[remStat](self).base + bonuses[remStat],
							--	dynamic[remStat](self).current + d.magnitudeThisFrame * math.min(1, d.duration / 60 * playerSection:get("percentagePerMinute") / 100)
							--))
							Actor.activeSpells(self):remove(b.activeSpellId)
							dbg("dispelled fortify "..math.floor(d.magnitudeThisFrame * math.min(1, d.duration / 60 * playerSection:get(remStat.."Restore") / 100)).." ("..d.magnitudeThisFrame..") "..remStat.." on self")
						end
					end
				end
			end
		end
	end
end)

function onFrame()
	--print(os.time())
	local remId = nil
	local remMagnitude = nil
	local remStat = nil
	local remDuration = nil
	local bonuses={
		health = 0,
		magicka = 0,
		fatigue = 0
	}
	--[[
	for a,b in pairs(bonuses) do
		if playerSection:get(a.."Restore") == 0 then
			bonuses[a] = nil
		end
	end
	]]
	for a,b in pairs(Actor.activeSpells(self)) do
		for c,d in pairs(b.effects) do
			if d.id == "fortifyhealth" or d.id == "fortifyfatigue" or d.id == "fortifymagicka" then
				local stat = d.id:sub(8,-1)
				bonuses[stat] = bonuses[stat]+d.magnitudeThisFrame
				--print(d.magnitudeThisFrame)
				--print(d.magnitudeMin)
				if d.duration and d.durationLeft < 0.2 and playerSection:get(stat.."Restore") ~= 0 then
					--print(d.durationLeft) -- when waiting: negative values
					remId = b.activeSpellId
					remMagnitude = d.magnitudeThisFrame
					remStat = stat
					remDuration = d.duration
				end
			end
		end
	end
	if remId then
		if playerSection:get(remStat.."FortifyBase") then
			dynamic[remStat](self).current = math.max(1+remMagnitude,math.min(
				dynamic[remStat](self).base,
				dynamic[remStat](self).current + remMagnitude * math.min(1, remDuration / 60 * playerSection:get(remStat.."Restore") / 100)
			))
		else
			dynamic[remStat](self).current = math.max(1+remMagnitude,math.min(
				dynamic[remStat](self).base + bonuses[remStat],
				dynamic[remStat](self).current + remMagnitude * math.min(1, remDuration / 60 * playerSection:get(remStat.."Restore") / 100)
			))
		end
		dbg("fortify "..remStat.." ran out, +"..remMagnitude.." "..remStat)
		Actor.activeSpells(self):remove(remId)
		bonuses[remStat] = bonuses[remStat] - remMagnitude
	end
	
	for a,b in pairs(bonuses) do
		if playerSection:get(a.."FortifyBase") then
			if buffCache[a] ~= b then
				dynamic[a](self).base = dynamic[a](self).base + b - buffCache[a]
				buffCache[a] = b
				
			end
		else
			if buffCache[a]>0 then
				dynamic[a](self).base = dynamic[a](self).base - buffCache[a]
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
	engineHandlers ={ 
		onFrame = onFrame,
		onLoad = onLoad,
		onSave = onSave,
		onInit = onInit,
	}
}

