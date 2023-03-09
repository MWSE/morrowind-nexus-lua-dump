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
   key = 'SolBowAimActivate',
   l10n = 'SolBowAimActivate',
   name = 'name',
   description = 'description',
})
-- default values!
local enabled = true
local includeThrown = false
local fatigueBow = 3.0
local fatigueZoom = 6.0
local enabledFirstPerson = true
local enabledThirdPerson = true
local combatOffsetX = 0
local combatOffsetY = 0
local aimingOffsetX = -10
local aimingOffsetY = -5
I.Settings.registerGroup({
  key = 'Settings_SolBowAimActivate',
  page = 'SolBowAimActivate',
  l10n = 'SolBowAimActivate',
  name = 'group_name',
  permanentStorage = true,
  settings = {
    boolSetting('enabled',enabled),
    boolSetting('includeThrown',includeThrown),
    numbSetting('fatigueBow',fatigueBow, false,0,10),
    numbSetting('fatigueZoom',fatigueZoom, false,0,10),
    boolSetting('enabledFirstPerson',enabledFirstPerson),
    boolSetting('enabledThirdPerson',enabledThirdPerson),
    numbSetting('combatOffsetX',combatOffsetX, true,-100,100),
    numbSetting('combatOffsetY',combatOffsetY, true,-100,100),
    numbSetting('aimingOffsetX',aimingOffsetX, true,-100,100),
    numbSetting('aimingOffsetY',aimingOffsetY, true,-100,100),
  },
})
local settingsGroup = storage.playerSection('Settings_SolBowAimActivate')
-- init
local combatOffset = util.vector2(40, -10)
local aimingOffset = util.vector2(10, -20)
-- update
local function updateSettings()
  enabled = settingsGroup:get('enabled')
  includeThrown = settingsGroup:get('includeThrown')
  fatigueBow = settingsGroup:get('fatigueBow')
  fatigueZoom = settingsGroup:get('fatigueZoom')
  enabledFirstPerson = settingsGroup:get('enabledFirstPerson')
  enabledThirdPerson = settingsGroup:get('enabledThirdPerson')
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
local hurtZoom = 0
local hurtWait = 2
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
        if fatigueBow > 0 then
          -- do isBowPrepared() but specifically for bow
          if Actor.stance(self) == Actor.STANCE.Weapon then
            local usedWeapon = Actor.equipment(self, Actor.EQUIPMENT_SLOT.CarriedRight)
            if (usedWeapon) then -- handtohand
              local weaponRecord = usedWeapon and usedWeapon.type == Weapon and Weapon.record(usedWeapon)
              if weaponRecord then
                -- if bow drawn
                if weaponRecord.type == Weapon.TYPE.MarksmanBow then -- 
                  if input.isActionPressed(input.ACTION.Use) then
                    -- drain fatigue on timer
                    if dynamic.fatigue(self).current > 0 then -- if not out of fatigue
                      hurtTime = hurtTime + dt
                      if hurtTime >= hurtWait then -- if enough time has passed
                        hurtTime = 0
                        local strength = Actor.stats.attributes.strength(self).modified
                        local fatigueCost =  math.ceil(fatigueBow*math.sqrt(1 + weaponRecord.weight)*100/(strength+50))
                        dynamic.fatigue(self).current = math.max(0,dynamic.fatigue(self).current - fatigueCost) -- don't set to below 0
                      end
                    end
                  end
                end
              end
            end
          end
        end
		
        if fatigueZoom > 0 and active then -- if zoomed in then check this junk
          -- drain fatigue on timer
          if dynamic.fatigue(self).current > 0 then -- if not out of fatigue
            hurtZoom = hurtZoom + dt
            if hurtZoom >= hurtWait then -- if enough time has passed
              hurtZoom = 0
			  -- we can assume that you have the correct weapon if the zoom is active
			  --local weaponWeight = Weapon.record(Actor.equipment(self, Actor.EQUIPMENT_SLOT.CarriedRight)).weight
              local fatigueCost =  math.ceil(fatigueZoom*100/(skills.marksman(self).modified+50))
              dynamic.fatigue(self).current = math.max(0,dynamic.fatigue(self).current - fatigueCost) -- don't set to below 0
            end
          end
        end
      
        local bowCheck = (enabledFirstPerson and camera.getMode() == camera.MODE.FirstPerson) or
            (enabledThirdPerson and camera.getMode() == camera.MODE.ThirdPerson)
        --local isSneak = self.controls.sneak -- 0.49 sneak check
        --if isSneak == nil then
        --  isSneak = input.isActionPressed(input.ACTION.Sneak) -- 0.48 sneak check
        --end
        --if active ~= (bowCheck and isBowPrepared() and isSneak and input.isActionPressed(input.ACTION.Activate)) then -- req sneak and activate
        if active ~= (bowCheck and isBowPrepared() and input.isActionPressed(input.ACTION.Activate)) then -- req activate only
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

