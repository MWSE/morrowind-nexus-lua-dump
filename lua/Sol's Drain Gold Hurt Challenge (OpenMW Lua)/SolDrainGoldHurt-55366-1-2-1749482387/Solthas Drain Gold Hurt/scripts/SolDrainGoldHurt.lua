local ui = require('openmw.ui') -- for displaying messages
local self = require('openmw.self')
local core = require('openmw.core') -- to send event to global script
local types = require('openmw.types')
local iui = require('openmw.interfaces').UI -- to disable rest menu if needed
local doOnce = true -- operate on first update that script is enabled, or when settings are changed

-- 0.48 chargen check
local input = require('openmw.input') -- this is literally only here to check if chargen is done for version 0.48
local hasStats = false -- used to determine if chargen is done

-- for damage
local ambient = require('openmw.ambient') -- 0.49 required?
local dynamic = types.Actor.stats.dynamic -- health etc
local currentHealthCost = 0

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
   key = 'SolDrainGoldHurt',
   l10n = 'SolDrainGoldHurt',
   name = 'name',
   description = 'description',
})
-- default values!
local enabled = true
local drainRate = 2
local doPercent = true
local hurtThreshold = 100
local checkTimer = 3.0
local healthCost = 1
local healthCostAccel = 1
local doPercentHurt = true
local allowRestWhileHurt = false
I.Settings.registerGroup({
	key = 'Settings_SolDrainGoldHurt',
	page = 'SolDrainGoldHurt',
	l10n = 'SolDrainGoldHurt',
	name = 'SolDrainGoldHurt',
	permanentStorage = true,
	settings = {
		boolSetting('enabled',enabled),
		numbSetting('drainRate',drainRate,false,0,100),
		boolSetting('doPercent',doPercent),
		numbSetting('hurtThreshold',hurtThreshold,true,0,1000),
		numbSetting('checkTimer',checkTimer,false,1.0,100.0),
		numbSetting('healthCost',healthCost,false,0.0,100.0),
		numbSetting('healthCostAccel',healthCostAccel,false,0.0,100.0),
		boolSetting('doPercentHurt',doPercentHurt),
		boolSetting('allowRestWhileHurt',allowRestWhileHurt),
	},
})
local settingsGroup = storage.playerSection('Settings_SolDrainGoldHurt')
-- update
local function updateSettings()
	enabled = settingsGroup:get('enabled')
	drainRate = settingsGroup:get('drainRate')
	doPercent = settingsGroup:get('doPercent')
	hurtThreshold = settingsGroup:get('hurtThreshold')
	checkTimer = settingsGroup:get('checkTimer')
	healthCost = settingsGroup:get('healthCost')
	healthCostAccel = settingsGroup:get('healthCostAccel')
	doPercentHurt = settingsGroup:get('doPercentHurt')
	allowRestWhileHurt = settingsGroup:get('allowRestWhileHurt')
end
local function init()
    updateSettings()
end
settingsGroup:subscribe(async:callback(updateSettings))

local drainTime = 0.0
local drainCount = 0
local currentGp = 0
local gameObjectGp = types.Actor.inventory(self):find('Gold_001')
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
					ui.showMessage("With this character's creation, the coin pouch of prophecy is severed. Disable Sol's Drain Gold Hurt to stitch up the weave of fate, or persist in the poor poor world you have created.")
				elseif not hasStats then
					return
				end
				
				if hasStats then
					doOnce = false
				end
			end

			-- cell logic
			if not doOnce then -- wait until chargen (and any other doOnce routine) is done
				drainTime = drainTime + dt
				if drainTime >= checkTimer then
					drainTime = 0.0
					currentGp = types.Actor.inventory(self):countOf('Gold_001')
					if currentGp <= hurtThreshold then
						-- from SolBodzCellLocked
						-- update health cost
						if currentHealthCost < 1 then
							currentHealthCost = healthCost
						else
							currentHealthCost = currentHealthCost + healthCostAccel
						end
						-- if health cost positive, then hit health each second
						if math.floor(currentHealthCost) > 0 then
							ui.showMessage('Your coin pouch burns! Ouch!')
							if ambient then --0.49 check
								ambient.playSound("Health Damage")
							end
							if not doPercentHurt then
								dynamic.health(self).current = math.max(0,dynamic.health(self).current - math.ceil(currentHealthCost)) -- don't set to below 0					
							else
								dynamic.health(self).current = math.max(0,dynamic.health(self).current - math.ceil(0.01*currentHealthCost*dynamic.health(self).base)) -- don't set to below 0					
							end
						end
					else
						currentHealthCost = 0
						gameObjectGp = types.Actor.inventory(self):find('Gold_001')
						if doPercent then
							drainCount = math.ceil(currentGp*0.01*drainRate)
						else
							drainCount = math.ceil(drainRate)
						end
						core.sendGlobalEvent('doRemoveItem',{count = drainCount, sender = gameObjectGp})
					end
				end
			end
		else
			doOnce = true
		end
	end,

	onFrame = function(dt)
		if enabled and (math.floor(currentHealthCost) > 0) and (not allowRestWhileHurt) then
			if iui.getMode()=="Rest" then
				iui.removeMode("Rest")
			end
		end
	end,
  }
}