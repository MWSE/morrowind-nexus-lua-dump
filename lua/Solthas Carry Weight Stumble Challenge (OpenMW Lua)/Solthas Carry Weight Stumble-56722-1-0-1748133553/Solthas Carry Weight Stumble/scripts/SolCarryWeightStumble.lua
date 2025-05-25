local ui = require('openmw.ui') -- for displaying messages
local self = require('openmw.self')
local types = require('openmw.types')
local doOnce = true -- operate on first update that script is enabled, or when settings are changed
local ambient = require('openmw.ambient') -- 0.49 required?
-- shorthand for convenience
local attributes = types.Actor.stats.attributes
local skills = types.NPC.stats.skills

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
   key = 'SolCarryWeightStumble',
   l10n = 'SolCarryWeightStumble',
   name = 'name',
   description = 'description',
})
-- default values!
local enabled = true
local drainRate = 10.0
local allowedTiers = 5
local onlyHighTiers = false
local baseMultiplier = 1.0
local hurtMultiplier = 0.5
local pratfallModifier = 0.25
local minThreshold = 0.0
local fixCapacity = 0
local jumpOnly = false
I.Settings.registerGroup({
	key = 'Settings_SolCarryWeightStumble',
	page = 'SolCarryWeightStumble',
	l10n = 'SolCarryWeightStumble',
	name = 'SolCarryWeightStumble',
	permanentStorage = true,
	settings = {
		boolSetting('enabled',enabled),
		numbSetting('drainRate',drainRate,false, 1.0, 100.0),
		numbSetting('allowedTiers',allowedTiers, false,1,5),
		boolSetting('onlyHighTiers',onlyHighTiers),
		numbSetting('baseMultiplier',baseMultiplier,false, 0.1, 10.0),
		numbSetting('hurtMultiplier',hurtMultiplier,false, 0.0, 10.0),
		numbSetting('pratfallModifier',pratfallModifier,false, 0.1, 0.5),
		numbSetting('fixCapacity',fixCapacity,true, 0, 1000),
		numbSetting('minThreshold',minThreshold,false, 0.0, 1000.0),
		boolSetting('jumpOnly',jumpOnly),
	},
})
local settingsGroup = storage.playerSection('Settings_SolCarryWeightStumble')
-- update
local function updateSettings()
	enabled = settingsGroup:get('enabled')
	drainRate = settingsGroup:get('drainRate')
	allowedTiers = settingsGroup:get('allowedTiers')
	onlyHighTiers = settingsGroup:get('onlyHighTiers')
	baseMultiplier = settingsGroup:get('baseMultiplier')
	hurtMultiplier = settingsGroup:get('hurtMultiplier')
	pratfallModifier = settingsGroup:get('pratfallModifier')
	fixCapacity = settingsGroup:get('fixCapacity')
	minThreshold = settingsGroup:get('minThreshold')
	jumpOnly = settingsGroup:get('jumpOnly')
end
local function init()
    updateSettings()
end
settingsGroup:subscribe(async:callback(updateSettings))

local dynamic = types.Actor.stats.dynamic -- health etc
local drainTime = 0.0
local encumbrance = 0.0
local capacity = 0.0
local mf = 0
local ms = 0
local runThreshold = 0.0
local movementEffect = 1.0
local isSneak = false
local luckEffect = 1.0
local healthEffect = 1.0
local fatigueEffect = 1.0
local jumpEffect = 1.0
local stumbleChance = 0.0
local didJump = false
local randRoll = 0.0
local hitMult = 1.0
local speedSet = 0
local athletSet = 0
local acrobSet = 0 
local didTrip = false
local jumpSpeedOverride = false
local minEncumbrance = 0
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
					ui.showMessage("With this mod's introduction, the balance of prophecy is weakened. Disable Sol's Carry Weight Stumble to restore the knees of fate, or persist in the deadly world in which you're stranded.")
				elseif not hasStats then
					return
				end
				
				if hasStats then
					doOnce = false
				end
			end

			if (not doOnce) and (not didTrip) then -- wait until chargen (and any other doOnce routine) is done
				mf = self.controls.movement
				ms = self.controls.sideMovement
				if types.Actor.isOnGround(self) and (not didJump) then
					if (not (mf == 0 and ms == 0)) and not jumpOnly then
						drainTime = drainTime + dt
					end
					if (drainTime >= drainRate) then
						drainTime = 0.0
						encumbrance = types.Actor.getEncumbrance(self) -- carry weight

						if (fixCapacity == 0) then
							capacity = types.NPC.getCapacity(self) -- carry capacity
						else
							capacity = fixCapacity
						end

						if (minThreshold == 0.0) then
							minEncumbrance = 0.0
						elseif (minThreshold < 1.0) then
							minEncumbrance = math.ceil(minThreshold*capacity)
						else
							minEncumbrance = minThreshold
						end

						if encumbrance >= minEncumbrance then -- only roll if you exceed the min
							-- if you are walking, halve the chance of stumbling
							if not jumpSpeedOverride then
								runThreshold = 0.5*(types.Actor.walkSpeed(self) + types.Actor.runSpeed(self)) -- set run threshold halfway between walk and run speeds
								if types.Actor.currentSpeed(self) >= runThreshold then
									movementEffect = 1.0
								else
									movementEffect = 0.5
								end
							else
								movementEffect = 1.0 -- if jumped, then treat the same as running
							end

							-- even safer if sneaking?
							isSneak = self.controls.sneak                         -- 0.49 sneak check
							if isSneak == nil then
								isSneak = input.isActionPressed(input.ACTION.Sneak) -- 0.48 sneak check (only works with hold to sneak)
							end
							if isSneak then
								movementEffect = 0.25
							end

							-- make luck etc have an effect too?
							luckEffect = 240.0/(160.0 + attributes.luck(self).modified + skills.athletics(self).modified)
							fatigueEffect = 1.2/(0.8 + (dynamic.fatigue(self).current/dynamic.fatigue(self).base))
							healthEffect = 240.0/(160.0 + attributes.endurance(self).modified + skills.athletics(self).modified) -- take less damage as level endurance and athletics

							-- add up the chance to stumble
							stumbleChance = encumbrance/capacity
							stumbleChance = stumbleChance*movementEffect -- running / jumping (1x), walking (0.5x), or sneaking (0.25x)
							stumbleChance = stumbleChance*luckEffect -- luck (1.5x at 0, 0.67x at 100) -- (3/2 vs 2/3)
							stumbleChance = stumbleChance*jumpEffect -- acrobatics, calculated at previous jump (2x at 0, 1x at 100+)
							stumbleChance = stumbleChance*fatigueEffect -- fatigue, 1.5x at empty, 0.67x at 100 percent -- (3/2 vs 2/3)
							stumbleChance = stumbleChance*baseMultiplier

							-- reset any jump-related effects
							jumpEffect = 1.0 -- now reset jump effect until you jump again
							jumpSpeedOverride = false

							randRoll = math.random()
							--print('base = ',randRoll, ' < ', stumbleChance, ' ?')
							if randRoll <= stumbleChance then -- likelihood of getting hurt = percent encumbrance
								randRoll = math.random() -- reroll so that you're not guaranteed to get worse if 1.0 multiplier and not fully encumbered
								if (allowedTiers >= 5) and (randRoll <= (pratfallModifier^4)*stumbleChance) then -- 1 in 256 chance at worst
									hitMult = 5.0 -- 5x damage if the worst happens?
									attributes.strength(self).damage = math.min(attributes.strength(self).base, attributes.strength(self).damage + math.ceil(0.2*(attributes.strength(self).base - attributes.strength(self).damage)))
									speedSet = math.min(attributes.speed(self).base, attributes.speed(self).damage + math.ceil(0.4*(attributes.speed(self).base - attributes.speed(self).damage)))
									attributes.agility(self).damage = math.min(attributes.agility(self).base, attributes.agility(self).damage + math.ceil(0.3*(attributes.agility(self).base - attributes.agility(self).damage)))
									attributes.endurance(self).damage = math.min(attributes.endurance(self).base, attributes.endurance(self).damage + math.ceil(0.3*(attributes.endurance(self).base - attributes.endurance(self).damage)))
									attributes.luck(self).damage = math.min(attributes.luck(self).base, attributes.luck(self).damage + math.ceil(0.5*(attributes.luck(self).base - attributes.luck(self).damage)))
									dynamic.fatigue(self).current = 0
									ui.showMessage("You broke your back! What a fool you are.")
								elseif (allowedTiers >= 4) and (randRoll <= (pratfallModifier^3)*stumbleChance) then -- 1 in 64 chance at worst
									hitMult = 3.34
									attributes.strength(self).damage = math.min(attributes.strength(self).base, attributes.strength(self).damage + math.ceil(0.1*(attributes.strength(self).base - attributes.strength(self).damage)))
									speedSet = math.min(attributes.speed(self).base, attributes.speed(self).damage + math.ceil(0.3*(attributes.speed(self).base - attributes.speed(self).damage)))
									attributes.agility(self).damage = math.min(attributes.agility(self).base, attributes.agility(self).damage + math.ceil(0.2*(attributes.agility(self).base - attributes.agility(self).damage)))
									attributes.endurance(self).damage = math.min(attributes.endurance(self).base, attributes.endurance(self).damage + math.ceil(0.2*(attributes.endurance(self).base - attributes.endurance(self).damage)))
									ui.showMessage("You broke your leg! By Azura, how did you manage that?")
								elseif (allowedTiers >= 3) and (randRoll <= (pratfallModifier^2)*stumbleChance) then -- 1 in 16 chance at worst
									hitMult = 2.24
									attributes.strength(self).damage = math.min(attributes.strength(self).base, attributes.strength(self).damage + math.ceil(0.05*(attributes.strength(self).base - attributes.strength(self).damage)))
									speedSet = math.min(attributes.speed(self).base, attributes.speed(self).damage + math.ceil(0.2*(attributes.speed(self).base - attributes.speed(self).damage)))
									ui.showMessage("You broke your toe! Yeeeeeeouch!")
								elseif (allowedTiers >= 2) and (randRoll <= pratfallModifier*stumbleChance) then -- 1 in 4 chance at worst
									hitMult = 1.50 -- each stage's multiplicatively increased hitMult is the quarter root of the max value, if the min is 1
										-- KNOCKDOWN?
									-- knocking down seems too annoying; let's damage speed instead. We'll max it out at base stat so it can't go below zero. 
									-- And we'll damage it by 1/10th of base-damage instead of modified, so that it won't react to them buffing speed.
									speedSet = math.min(attributes.speed(self).base, attributes.speed(self).damage + math.ceil(0.1*(attributes.speed(self).base - attributes.speed(self).damage)))
									ui.showMessage('You twisted your ankle! Ouch!')
								elseif not onlyHighTiers then
									hitMult = 1.0
									speedSet = math.min(attributes.speed(self).base, attributes.speed(self).damage)
									ui.showMessage('You stubbed your toe!')
								else
									hitMult = 0.0
								end
								if hitMult > 0.0 then -- don't bother if rolled lowest tier, but only allow higher tiers
									dynamic.health(self).current = math.max(0,dynamic.health(self).current - math.ceil(hurtMultiplier*hitMult*healthEffect*math.sqrt(encumbrance)))
									if ambient then --0.49 check
										if (hurtMultiplier > 0.0) then -- only play sound effect if you actually take damage
											ambient.playSound("Health Damage")
										end
									end
									-- speed handling -- kill speed after saving what it's supposed to go to
									attributes.speed(self).damage = attributes.speed(self).modified
									athletSet = skills.athletics(self).damage
									skills.athletics(self).damage = skills.athletics(self).modified
									acrobSet = skills.acrobatics(self).damage
									skills.acrobatics(self).damage = skills.acrobatics(self).modified
									-- then start a timer to restore it to setSpeed value
									-- use hitMult for the timer because it already ramps up linearly?
									didTrip = true
									async:newUnsavableSimulationTimer(
										0.5*hitMult, 
										function()
											didTrip = false -- this is needed to prevent timer stacking
											attributes.speed(self).damage = speedSet
											skills.athletics(self).damage = athletSet
											skills.acrobatics(self).damage = acrobSet
										end
									)
								end
							end
						end
					end
				end
				-- if jumped and skipped above check, then allow next check
				if didJump then
					didJump = false
				end
			end
		else
			doOnce = true
		end
	end,

    onInputAction = function(id)
		if enabled then
			if (id == input.ACTION.Jump) then
				isSneak = self.controls.sneak                           -- 0.49 sneak check
				if isSneak == nil then
					isSneak = input.isActionPressed(input.ACTION.Sneak) -- 0.48 sneak check (only works with hold to sneak)
				end
				if types.Actor.isOnGround(self) and not isSneak then
					drainTime = drainRate -- if you jump and are not sneaking, then you have a chance to stumble as soon as you land
					didJump = true
					jumpSpeedOverride = true
					jumpEffect = math.max(1.0, (200.0 - skills.acrobatics(self).modified)/100.0)
				end
			end
		end
	end,
  }
}