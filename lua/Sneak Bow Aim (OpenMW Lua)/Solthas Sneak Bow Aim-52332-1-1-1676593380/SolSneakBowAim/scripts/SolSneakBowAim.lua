--local core = require('openmw.core')
local camera = require('openmw.camera')
local util = require('openmw.util')
--local nearby = require('openmw.nearby')
local self = require('openmw.self')
local Actor = require('openmw.types').Actor
local skills = require('openmw.types').NPC.stats.skills
local Weapon = require('openmw.types').Weapon
local input = require('openmw.input')
local dynamic = require('openmw.types').Actor.stats.dynamic

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
   key = 'SolSneakBowAim',
   l10n = 'SolSneakBowAim',
   name = 'name',
   description = 'description',
})
-- default values!
local enabled = true
local fatigueMult = 1.0
local includeThrown = false
local enabledFirstPerson = true
local combatOffsetX = 40
local combatOffsetY = -20
local enabledThirdPerson = true
local aimingOffsetX = 10
local aimingOffsetY = -20
I.Settings.registerGroup({
  key = 'Settings_SolSneakBowAim',
  page = 'SolSneakBowAim',
  l10n = 'SolSneakBowAim',
  name = 'group_name',
  permanentStorage = true,
  settings = {
    boolSetting('enabled',enabled),
    numbSetting('fatigueMult',fatigueMult, false,0,2),
    boolSetting('includeThrown',includeThrown),
    boolSetting('enabledFirstPerson',enabledFirstPerson),
    numbSetting('combatOffsetX',combatOffsetX, true,-100,100),
    numbSetting('combatOffsetY',combatOffsetY, true,-100,100),
    boolSetting('enabledThirdPerson',enabledThirdPerson),
    numbSetting('aimingOffsetX',aimingOffsetX, true,-100,100),
    numbSetting('aimingOffsetY',aimingOffsetY, true,-100,100),
  },
})
local settingsGroup = storage.playerSection('Settings_SolSneakBowAim')
-- init
local combatOffset = util.vector2(40, -10)
local aimingOffset = util.vector2(10, -20)
-- update
local function updateSettings()
  enabled = settingsGroup:get('enabled')
  enabledFirstPerson = settingsGroup:get('enabledFirstPerson')
  enabledThirdPerson = settingsGroup:get('enabledThirdPerson')
  fatigueMult = settingsGroup:get('fatigueMult')
  includeThrown = settingsGroup:get('includeThrown')
  combatOffsetX = settingsGroup:get('combatOffsetX')
  combatOffsetY = settingsGroup:get('combatOffsetY')
  aimingOffsetX = settingsGroup:get('aimingOffsetX')
  aimingOffsetY = settingsGroup:get('aimingOffsetY')
    combatOffset = util.vector2(combatOffsetX, combatOffsetY)
    aimingOffset = util.vector2(aimingOffsetX, aimingOffsetY)
end
local function init()
    updateSettings()
end
settingsGroup:subscribe(async:callback(updateSettings))



local function isBowPrepared()
    if Actor.stance(self) ~= Actor.STANCE.Weapon then return false end
    local item = Actor.equipment(self, Actor.EQUIPMENT_SLOT.CarriedRight)
    local weaponRecord = item and item.type == Weapon and Weapon.record(item)
    if not weaponRecord then return false end
	local returnType = (weaponRecord.type == Weapon.TYPE.MarksmanBow or weaponRecord.type == Weapon.TYPE.MarksmanCrossbow) -- no thrown
	if includeThrown then
		returnType = (returnType or weaponRecord.type == Weapon.TYPE.MarksmanThrown)
	end
    return returnType
end

-- hurt logic
local hurtTime = 0
local hurtWait = 2
local hurtVal = 5
-- init
local active = false
local counterMin, counterMax = -3, 2
local counter = counterMin
local useAimingOffset = false
return {
  engineHandlers = { 
    -- init settings
    onActive = init,

    onUpdate = function(dt)
    if enabled then
      -- if arrow drawn and you're using a bow specifically... drain fatigue?
      if fatigueMult > 0 then
        -- do isBowPrepared() but specifically for bow
        if Actor.stance(self) == Actor.STANCE.Weapon then
          local usedWeapon = Actor.equipment(self, Actor.EQUIPMENT_SLOT.CarriedRight)
		  if (usedWeapon) then -- handtohand
			local weaponRecord = usedWeapon and usedWeapon.type == Weapon and Weapon.record(usedWeapon)
			if  weaponRecord then
		      if weaponRecord.type == Weapon.TYPE.MarksmanBow then -- 
				if input.isActionPressed(input.ACTION.Use) then
				  -- drain fatigue on timer
				  if dynamic.fatigue(self).current > 0 then -- if out of fatigue
					hurtTime = hurtTime + dt
					if hurtTime >= hurtWait then -- if enough time has passed
					  hurtTime = 0
                      local strength = Actor.stats.attributes.strength(self).modified
					  local fatigueCost =  math.ceil(fatigueMult*math.sqrt(weaponRecord.weight)*hurtVal*100/(strength+50))
					  dynamic.fatigue(self).current = math.max(0,dynamic.fatigue(self).current - fatigueCost) -- don't set to below 0
					end
				  end
				end
              end
            end
          end
        end
      end
    
      local bowCheck = (enabledFirstPerson and camera.getMode() == camera.MODE.FirstPerson) or
          (enabledThirdPerson and camera.getMode() == camera.MODE.ThirdPerson)
      local isSneak = self.controls.sneak -- 0.49 sneak check
      if isSneak == nil then
        isSneak = input.isActionPressed(input.ACTION.Sneak) -- 0.48 sneak check
      end
      if active ~= (bowCheck and isBowPrepared() and isSneak and input.isActionPressed(input.ACTION.Activate)) then -- req sneak and activate
      --if active ~= (bowCheck and isBowPrepared() and isSneak) then -- req sneak
      --if active ~= (bowCheck and isBowPrepared()) then -- original
      active = not active
      if active then
        I.Camera.disableThirdPersonOffsetControl()
        camera.setFocalTransitionSpeed(5.0)
        camera.setFocalPreferredOffset(combatOffset)
      else
        I.Camera.enableThirdPersonOffsetControl()
      end
      end
      if self.controls.use == 0 or not active then
      counter = math.max(counterMin, counter - dt * 2.5)
      else
      counter = math.min(counterMax, counter + dt * 2.5)
      end
      local effect = (math.max(0.1, math.exp(math.min(1, counter)-1)) - 0.1) / 0.9
      effect = effect*math.min(1.5,(0.5 + skills.marksman(self).modified/100))
      camera.setFieldOfView(camera.getBaseFieldOfView() * (1 - 0.5 * effect))
      if camera.getMode() ~= camera.MODE.ThirdPerson then effect = 0 end
      if useAimingOffset ~= (effect > 0.4) and active then
      useAimingOffset = effect > 0.4
      if useAimingOffset then
        camera.setFocalPreferredOffset(aimingOffset)
      else
        camera.setFocalPreferredOffset(combatOffset)
      end
      end
    end
    end
  }
}

