local ui = require('openmw.ui') -- for displaying messages
local self = require('openmw.self')
local types = require('openmw.types')
local doOnce = true -- operate on first update that script is enabled, or when settings are changed
local ambient = require('openmw.ambient') -- 0.49 required?

-- 0.48 chargen check
local input = require('openmw.input') -- this is literally only here to check if chargen is done for version 0.48
local hasStats = false                -- used to determine if chargen is done

-- Make it so the buffs / debuffs decay slowly with time??? Maybe one every 10 seconds, for every skill.

-- settings functions
local function boolSetting(sKey, sDef)
	return {
		key = sKey,
		renderer = 'checkbox',
		name = sKey .. '_name',
		description = sKey .. '_desc',
		default = sDef,
	}
end
local function numbSetting(sKey, sDef, sInt, sMin, sMax)
	return {
		key = sKey,
		renderer = 'number',
		name = sKey .. '_name',
		description = sKey .. '_desc',
		default = sDef,
		argument = {
			integer = sInt,
			min = sMin,
			max = sMax,
		},
	}
end
-- handle settings
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local async = require('openmw.async')
I.Settings.registerPage({
	key = 'SolSkillHistorySwap',
	l10n = 'SolSkillHistorySwap',
	name = 'name',
	description = 'description',
})
-- default values!
local enabled = true
local timeResolution = 1.0
local buffRate = 10
local hurtPastZero = 1
local proportionalChance = true
local excludeAcroAthl = true
local reduceLevel100s = 99
local add100sToModifier = true
local doHardMode = false
I.Settings.registerGroup({
	key = 'Settings_SolSkillHistorySwap',
	page = 'SolSkillHistorySwap',
	l10n = 'SolSkillHistorySwap',
	name = 'SolSkillHistorySwap',
	permanentStorage = true,
	settings = {
		boolSetting('enabled', enabled),
		numbSetting('timeResolution', timeResolution, false, 0.1, 10.0),
		numbSetting('buffRate', buffRate, true, 1, 100),
		numbSetting('hurtPastZero', hurtPastZero, true, 0, 1000),
		boolSetting('proportionalChance', proportionalChance),
		boolSetting('excludeAcroAthl', excludeAcroAthl),
		numbSetting('reduceLevel100s', reduceLevel100s, true, 1, 100),
		boolSetting('add100sToModifier', add100sToModifier),
		boolSetting('doHardMode', doHardMode),
	},
})
local settingsGroup = storage.playerSection('Settings_SolSkillHistorySwap')
-- update
local function updateSettings()
	enabled = settingsGroup:get('enabled')
	timeResolution = settingsGroup:get('timeResolution')
	buffRate = settingsGroup:get('buffRate')
	hurtPastZero = settingsGroup:get('hurtPastZero')
	proportionalChance = settingsGroup:get('proportionalChance')
	excludeAcroAthl = settingsGroup:get('excludeAcroAthl')
	reduceLevel100s = settingsGroup:get('reduceLevel100s')
	add100sToModifier = settingsGroup:get('add100sToModifier')
	doHardMode = settingsGroup:get('doHardMode')
end
local function init()
	updateSettings()
end
settingsGroup:subscribe(async:callback(updateSettings))

-- init list of skills and how they've been modified
local skillList = {}
local skillBase = {}
local skillProg = {}
local skillMods = {}
local skillDams = {}
local skillWait = {}
for k, v in pairs(types.NPC.stats.skills) do -- save as table of strings of same format as class.SKILLS
	skillList[#skillList + 1] = k
	skillProg[#skillBase + 1] = 0
	skillProg[#skillProg + 1] = 0.0
	skillMods[#skillMods + 1] = 0
	skillDams[#skillDams + 1] = 0
	skillWait[#skillWait + 1] = 0
end

-- save state to be removed on load
local function onSave()
	return {
		skillBase = skillBase,
		skillProg = skillProg,
		skillMods = skillMods,
		skillDams = skillDams,
		skillWait = skillWait
	}
end
local function onLoad(data)
	if data then
		if data.skillBase then
			skillBase = data.skillBase
		end
		if data.skillProg then
			skillProg = data.skillProg
		end
		if data.skillMods then
			skillMods = data.skillMods
		end
		if data.skillDams then
			skillDams = data.skillDams
		end
		if data.skillWait then
			skillWait = data.skillWait
		end
	end
end

local skills = types.NPC.stats.skills
local function skillSelect(kExclude)
	local statSelect = {}
	local currentProb = 0
	for k,v in pairs(skillList) do -- add up all current stats to then roll against
		if (k ~= kExclude) then
			-- get current stat
			if proportionalChance then
				currentProb = skills[v](self).base + skills[v](self).modifier - skills[v](self).damage
				statSelect[#statSelect + 1] = math.max(1, 101 - currentProb) -- weight 100 at level 1, weight 1 at level 100
			else
				-- might as well do it all here because this function already excludes the current stat
				statSelect[#statSelect + 1] = 1
			end
			-- and additionally add sum of previous entries to get a cumsum
			if k > 1 then
				if (k == 2) and (kExclude == 1) then
					statSelect[#statSelect] = statSelect[#statSelect]
				else
					statSelect[#statSelect] = statSelect[#statSelect] + statSelect[#statSelect - 1]
				end
			end
		end
	end
	local statIdx = math.random(statSelect[#statSelect])
	for k,v in pairs(statSelect) do
		if statIdx <= v then
			if k >= kExclude then -- skip over the excluded skill index
				k = k + 1
			end
			return k
		end
	end
end

local drainTime = 0.0
local kBuffed = {}
local kDebuff = 0
local testStat = 0
local newHealth = 0
return {
	engineHandlers = {
		-- init settings
		onActive = init,
		onSave = onSave,
		onLoad = onLoad,

		onUpdate = function(dt)
			if enabled then
				if doOnce then
					-- do not proceed further until chargen is done
					-- for 0.49, a better check will be for the first quest's status, inside an ambient block
					if not hasStats and input.getControlSwitch(input.CONTROL_SWITCH.ViewMode) then -- 0.48-compatible check
						hasStats = true
						ui.showMessage("With this mod's introduction, the thread of prophecy turns lopsided. Disable Sol's Skill History Swap to restore the stability of fate, or persist in horror as this world you have created punishes you for the history of your actions.")
						-- and update skill progress so the mod doesn't immediately debuff every skill
						for k, v in pairs(skillList) do
							skillBase[k] = skills[v](self).base
							skillProg[k] = skills[v](self).progress
							-- and if you're excluding acrobatics and athletics, make sure their buffs/buffs from this mod are nulled here
							if (excludeAcroAthl and ((v == "acrobatics") or (v == "athletics"))) then
								-- and if you are excluding them, make sure they're reset
								if skillDams[k] > 0 then -- don't debuff if already buffed; remove buff instead
									skills[v](self).damage = skills[v](self).damage - skillDams[k]
									skillDams[k] = 0
								end
								if skillMods[k] > 0 then
									skills[v](self).modifier = skills[v](self).modifier - skillMods[k]
									skillMods[k] = 0
								end
							end
						end
					elseif not hasStats then
						return
					end

					if hasStats then
						doOnce = false
					end
				end

				if not doOnce then -- wait until chargen (and any other doOnce routine) is done
					drainTime = drainTime + dt
					if drainTime >= timeResolution then
						drainTime = 0.0

						kBuffed = {} -- reset list of debuffed skills
						for k, v in pairs(skillList) do
							-- let's add in a little safety because skillWait should never be negative
							if skillWait[k] < 0.0 then
								skillWait[k] = skillWait[k] + 1 -- instead of resetting to zero outright, increment and eventually it'll zero out
							end
							-- Another safety; by default you cannot level skills at 100, so reduce them?
							if (reduceLevel100s < 100) and (skills[v](self).base >= 100) then
								if add100sToModifier then
									skills[v](self).modifier = skills[v](self).modifier + (skills[v](self).base - reduceLevel100s)
								end
								skills[v](self).base = reduceLevel100s
							end

							if not (excludeAcroAthl and ((v == "acrobatics") or (v == "athletics"))) then
								if (skillWait[k] >= 1) or (skills[v](self).base > skillBase[k]) or (skills[v](self).progress > skillProg[k]) then -- only debuff if gained a level or gained xp towards one
									skillWait[k] = skillWait[k] + math.max(0, buffRate*(skills[v](self).base - skillBase[k])) -- don't subtract if player loses level
									skillBase[k] = skills[v](self).base -- save progress so it doesn't repeat
									skillWait[k] = skillWait[k] + buffRate*(skills[v](self).progress - skillProg[k]) -- will need to be able to subtract if player gains level however
									skillProg[k] = skills[v](self).progress -- save progress so it doesn't repeat
									--print(v, skillWait[k], skills[v](self).base, skillBase[k], skills[v](self).progress, skillProg[k]) -- debug

									-- And also apply the debuff, but only if there's room to do so
									if doHardMode then
										testStat = skills[v](self).base
									else
										testStat = skills[v](self).base + skills[v](self).modifier - skills[v](self).damage
									end
									if (skillWait[k] >= 1) and (testStat > 0) then
										kBuffed[#kBuffed + 1] = k -- save index to list so you don't buff it later
										skillWait[k] = skillWait[k] - 1
										if not doHardMode then
											if skillMods[k] > 0 then -- don't debuff if already buffed; remove buff instead
												skills[v](self).modifier = skills[v](self).modifier - 1
												skillMods[k] = skillMods[k] - 1
											else
												skills[v](self).damage = skills[v](self).damage + 1
												skillDams[k] = skillDams[k] + 1
											end
										else
											if skills[v](self).base >= 1 then
												skills[v](self).base = skills[v](self).base - 1
											end
										end
									elseif (skillWait[k] >= 1) then -- if no room to debuff, then clear the buffer
										if hurtPastZero > 0 then
											if ambient then
												ambient.playSound("Health Damage", {volume = 0.25 + math.min(0.75, 0.05*hurtPastZero*math.floor(skillWait[k]))}) -- 0.5 if 1 damage, 1.0 if 10+ damage
											end
											newHealth = types.Actor.stats.dynamic.health(self).current - hurtPastZero*math.floor(skillWait[k])
											types.Actor.stats.dynamic.health(self).current = math.max(0, newHealth)
										end
										skillWait[k] = skillWait[k]%1 -- remove remaining, but keep remainder
									end
								end
							end
						end

						-- now, for each debuffed skill, do a buff pass
						for k, v in pairs(kBuffed) do
							kDebuff = skillSelect(v)
							if kDebuff then -- must be able to find a skill to buff
								if skillDams[kDebuff] > 0 then -- don't buff if already debuffed; remove debuff instead
									skills[skillList[kDebuff]](self).damage = skills[skillList[kDebuff]](self).damage - 1
									skillDams[kDebuff] = skillDams[kDebuff] - 1
								elseif skillMods[kDebuff] then
									skills[skillList[kDebuff]](self).modifier = skills[skillList[kDebuff]](self).modifier + 1
									skillMods[kDebuff] = skillMods[kDebuff] + 1
								end
							end
						end
					end
				end
			else
				if not doOnce then
					-- on the first frame it's disabled, go through all stats and remove skillMods and Dams if possible
					for k, v in pairs(skillList) do
						if skillDams[k] > 0 then -- don't debuff if already buffed; remove buff instead
							skills[v](self).damage = skills[v](self).damage - skillDams[k]
							skillDams[k] = 0
						end
						if skillMods[k] > 0 then
							skills[v](self).modifier = skills[v](self).modifier - skillMods[k]
							skillMods[k] = 0
						end
					end
				end
				doOnce = true
			end
		end
	}
}
