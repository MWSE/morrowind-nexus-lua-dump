local ui = require('openmw.ui') -- for displaying messages
local self = require('openmw.self')
local types = require('openmw.types')
local doOnce = true -- operate on first update that script is enabled, or when settings are changed

-- 0.48 chargen check
local input = require('openmw.input') -- this is literally only here to check if chargen is done for version 0.48
local hasStats = false -- used to determine if chargen is done

-- settings functions
local function boolSetting(sKey, sDef)
    return {
        key = sKey,
        renderer = 'checkbox',
        name = sKey..'_name',
        description = sKey..'_desc',
        default = sDef,
    }
end
local function numbSetting(sKey, sDef, sInt, sMin, sMax)
    return {
        key = sKey,
        renderer = 'number',
        name = sKey..'_name',
        description = sKey..'_desc',
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
   key = 'SolRandomStatDecay',
   l10n = 'SolRandomStatDecay',
   name = 'name',
   description = 'description',
})
-- default values!
local enabled = true
local proportionalChance = true
local drainRate = 2.0
local drainAmount = 1
local fatigueMult0 = 20.0
local percentageHit = true
local allowStrength = true
local minStatVal = 0
I.Settings.registerGroup({
	key = 'Settings_SolRandomStatDecay',
	page = 'SolRandomStatDecay',
	l10n = 'SolRandomStatDecay',
	name = 'SolRandomStatDecay',
	permanentStorage = true,
	settings = {
		boolSetting('enabled',enabled),
		boolSetting('proportionalChance',proportionalChance),
		numbSetting('drainRate',drainRate,false, 0.1, 100.0),
		numbSetting('drainAmount',drainAmount,true, 1, 100),
		numbSetting('fatigueMult0',fatigueMult0,false, 0.1, 100.0),
		boolSetting('percentageHit',percentageHit),
		boolSetting('allowStrength',allowStrength),
		numbSetting('minStatVal',minStatVal,true, 0, 1),
	},
})
local settingsGroup = storage.playerSection('Settings_SolRandomStatDecay')
-- update
local function updateSettings()
	enabled = settingsGroup:get('enabled')
	proportionalChance = settingsGroup:get('proportionalChance')
	drainRate = settingsGroup:get('drainRate')
	drainAmount = settingsGroup:get('drainAmount')
	fatigueMult0 = settingsGroup:get('fatigueMult0')
	percentageHit = settingsGroup:get('percentageHit')
	allowStrength = settingsGroup:get('allowStrength')
	minStatVal = settingsGroup:get('minStatVal')
end
local function init()
    updateSettings()
end
settingsGroup:subscribe(async:callback(updateSettings))


local dynamic = types.Actor.stats.dynamic -- health etc
local attributes = types.Actor.stats.attributes
local skills = types.NPC.stats.skills
local drainTime = 0.0

-- set up stat table reference
local statTable = {}
	statTable[#statTable + 1] = dynamic.health(self)
	statTable[#statTable + 1] = dynamic.magicka(self)
	statTable[#statTable + 1] = dynamic.fatigue(self)
	-- 8 attributes
	statTable[#statTable + 1] = attributes.strength(self)
	statTable[#statTable + 1] = attributes.intelligence(self)
	statTable[#statTable + 1] = attributes.willpower(self)
	statTable[#statTable + 1] = attributes.agility(self)
	statTable[#statTable + 1] = attributes.speed(self)
	statTable[#statTable + 1] = attributes.endurance(self)
	statTable[#statTable + 1] = attributes.personality(self)
	statTable[#statTable + 1] = attributes.luck(self)
	-- 27 skills
	--combat
	statTable[#statTable + 1] = skills.armorer(self)
	statTable[#statTable + 1] = skills.athletics(self)
	statTable[#statTable + 1] = skills.axe(self)
	statTable[#statTable + 1] = skills.block(self)
	statTable[#statTable + 1] = skills.bluntweapon(self)
	statTable[#statTable + 1] = skills.heavyarmor(self)
	statTable[#statTable + 1] = skills.longblade(self)
	statTable[#statTable + 1] = skills.mediumarmor(self)
	statTable[#statTable + 1] = skills.spear(self)
	--magic
	statTable[#statTable + 1] = skills.alchemy(self)
	statTable[#statTable + 1] = skills.alteration(self)
	statTable[#statTable + 1] = skills.conjuration(self)
	statTable[#statTable + 1] = skills.destruction(self)
	statTable[#statTable + 1] = skills.enchant(self)
	statTable[#statTable + 1] = skills.illusion(self)
	statTable[#statTable + 1] = skills.mysticism(self)
	statTable[#statTable + 1] = skills.restoration(self)
	statTable[#statTable + 1] = skills.unarmored(self)
	--stealth
	statTable[#statTable + 1] = skills.acrobatics(self)
	statTable[#statTable + 1] = skills.handtohand(self)
	statTable[#statTable + 1] = skills.lightarmor(self)
	statTable[#statTable + 1] = skills.marksman(self)
	statTable[#statTable + 1] = skills.mercantile(self)
	statTable[#statTable + 1] = skills.security(self)
	statTable[#statTable + 1] = skills.shortblade(self)
	statTable[#statTable + 1] = skills.sneak(self)
	statTable[#statTable + 1] = skills.speechcraft(self)

local function proportionalSelect()
	local statSelect = {}
	for k,v in pairs(statTable) do -- add up all current stats to then roll against
		-- get current stat
		if k <= 3 then -- if dynamic
			statSelect[k] = v.current
		else
			statSelect[k] = v.base - v.damage
		end
		-- and additionally add sum of previous entries to get a cumsum
		if k > 1 then
			statSelect[k] = statSelect[k] + statSelect[k - 1]
		end
	end
	local statIdx = math.random(statSelect[#statSelect])
	for k,v in pairs(statSelect) do
		if statIdx <= v then
			return k
		end
	end
end

local statIdx = 0
local fatigueMult = 1.0
return {
  engineHandlers = { 
    -- init settings
    onActive = init,

    onUpdate = function(dt)
		if enabled then
			if doOnce then
				-- do not proceed further until chargen is done
				-- for 0.49, a better check will be for the first quest's status, inside an ambient block
				if not hasStats and input.getControlSwitch(input.CONTROL_SWITCH.ViewMode) then -- 0.48-compatible check
					hasStats = true
					ui.showMessage("With this mod's introduction, the thread of prophecy is in decline. Disable Sol's Random Stat Decay to restore the stability of fate, or persist in the rotting world you have created.")
				elseif not hasStats then
					return
				end
				
				if hasStats then
					doOnce = false
				end
			end

			if not doOnce then -- wait until chargen (and any other doOnce routine) is done
				drainTime = drainTime + dt
				if drainTime >= drainRate then
					drainTime = 0.0

					if not proportionalChance then
						statIdx = math.random(#statTable)
					else
						statIdx = proportionalSelect()
					end

					if statIdx == 3 then
						fatigueMult = fatigueMult0
					else
						fatigueMult = 1.0
					end

					-- number of stats... 3 dynamic, 8 attributes, 27 skills
					if statIdx <= 3 then -- if dynamic health, magicka, or fatigue
						if percentageHit then
							statTable[statIdx].current = math.max(minStatVal, statTable[statIdx].current - math.ceil(0.01*fatigueMult*drainAmount*statTable[statIdx].current)) -- reduce current by 1%, or 10% for fatigue
						else
							statTable[statIdx].current = math.max(minStatVal, statTable[statIdx].current - math.ceil(fatigueMult*drainAmount)) -- reduce current by 1, or 10x for fatigue
						end
					elseif statIdx == 4 then -- STRENGTH
						if allowStrength then
							-- copied from below
							if percentageHit then
								statTable[statIdx].damage = math.min(statTable[statIdx].base-minStatVal, statTable[statIdx].damage + math.ceil(0.01*drainAmount*(statTable[statIdx].base-statTable[statIdx].damage))) -- add 1% damage
							else
								statTable[statIdx].damage = math.min(statTable[statIdx].base-minStatVal, statTable[statIdx].damage + drainAmount) -- add 1 damage
							end
						else -- if not hitting strength, then hit health, magicka, and fatigue at half effectiveness
							-- copied from above
							if percentageHit then
								statTable[1].current = math.max(minStatVal, statTable[1].current - math.ceil(0.5*0.01*drainAmount*statTable[1].current)) -- health at 1/2
								statTable[2].current = math.max(minStatVal, statTable[2].current - math.ceil(0.5*0.01*drainAmount*statTable[2].current)) -- magicka at 1/2
								statTable[3].current = math.max(minStatVal, statTable[3].current - math.ceil(0.5*0.01*fatigueMult*drainAmount*statTable[3].current)) -- fatigue at 5x
							else
								statTable[1].current = math.max(minStatVal, statTable[1].current - math.ceil(0.5*drainAmount)) -- health at 1/2 if possible
								statTable[2].current = math.max(minStatVal, statTable[2].current - math.ceil(0.5*drainAmount)) -- magicka at 1/2 if possible
								statTable[3].current = math.max(minStatVal, statTable[3].current - math.ceil(0.5*fatigueMult*drainAmount)) -- fatigue at 5x
							end
						end
					else
						if percentageHit then
							statTable[statIdx].damage = math.min(statTable[statIdx].base-minStatVal, statTable[statIdx].damage + math.ceil(0.01*drainAmount*(statTable[statIdx].base-statTable[statIdx].damage))) -- add 1% damage
						else
							statTable[statIdx].damage = math.min(statTable[statIdx].base-minStatVal, statTable[statIdx].damage + drainAmount) -- add 1 damage
						end
					end
				end
			end
		else
			doOnce = true
		end
	end,
  }
}