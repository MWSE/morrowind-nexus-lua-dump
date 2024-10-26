local self = require('openmw.self')
local Core = require('openmw.core')
local Types = require('openmw.types')
local Storage = require('openmw.storage')
local Async = require('openmw.async')
local SoundPlayer = require('Scripts.MaxarFootsteps.FootstepsSound')

local settingsGroup = Storage.globalSection('Settings_foot')
local settings = {
  isFeatureEnabled = true,
  volume = 1.0,
  footstepInterval = 1.0,
  baseRunningSpeed = 105,
  baseWalkingSpeed = 70,
  baseBeastRunningSpeed = 85,
  baseBeastWalkingSpeed = 53,
  baseSneakingSpeed = 54,
  baseBeastSneakingSpeed = 54,
  imUsingController = false
}
local function updateSettingsFromStorage()
  settings.volume = settingsGroup:get('volume') / 100
  settings.footstepInterval = settingsGroup:get('footstepInterval')
  settings.baseRunningSpeed = settingsGroup:get('baseRunningSpeed')
  settings.baseWalkingSpeed = settingsGroup:get('baseWalkingSpeed')
  settings.baseBeastRunningSpeed = settingsGroup:get('baseBeastRunningSpeed')
  settings.baseBeastWalkingSpeed = settingsGroup:get('baseBeastWalkingSpeed')
  settings.baseSneakingSpeed = settingsGroup:get('baseSneakingSpeed')
  settings.baseBeastSneakingSpeed = settingsGroup:get('baseBeastSneakingSpeed')
  settings.imUsingController = settingsGroup:get('imUsingController')
end
settingsGroup:subscribe(Async:callback(updateSettingsFromStorage))

local isBeast = false
local function contains(array, value)
  for _, v in ipairs(array) do
      if v == value then
          return true
      end
  end
  return false
end
local function initializeRace()
  updateSettingsFromStorage()
  local race = Types.NPC.record(self).race
  isBeast = contains({"khajiit", "argonian"}, race)
end

local function isMoving()
  local currentSpeed = Types.Actor.getCurrentSpeed(self)
  return currentSpeed > 0
end

local function isSneaking()
  return self.controls.sneak
end

local function isWalking()
  return isMoving() and not self.controls.run
end

local lastSpeed = 0
local function calculateFootstepTime()
  local currentSpeed = Types.Actor.getRunSpeed(self)
  if settings.imUsingController then
    currentSpeed = Types.Actor.getCurrentSpeed(self)
  end
  local baseFootstepTime = settings.footstepInterval

  --Running speed
  local baseSpeed = settings.baseRunningSpeed
  if isBeast then
    baseSpeed = settings.baseBeastRunningSpeed
  end

  --Walking speed
  if isWalking() then
    baseSpeed = settings.baseWalkingSpeed
    currentSpeed = Types.Actor.getWalkSpeed(self)
    if isBeast then
      baseSpeed = settings.baseBeastWalkingSpeed
    end
  end
  
  --Sneaking speed
  if isSneaking() then
    baseSpeed = settings.baseSneakingSpeed
    if isBeast then
      baseSpeed = settings.baseBeastSneakingSpeed
    end
  end

  if settings.imUsingController or isSneaking() then
    currentSpeed = Types.Actor.getCurrentSpeed(self)
  end

  local speedRatio = baseSpeed / currentSpeed
  local footstepTime = baseFootstepTime * speedRatio
  return math.max(footstepTime, 0.1) -- Ensure footstepTime doesn't get too small
end

local lastIsOnGround = false
local lastFootstepTime = 0 
local lastWaterHeight = nil
return {
  engineHandlers = {
    onActive = initializeRace(),
    onUpdate = function(deltaTime)
      if not settings.isFeatureEnabled then return end
      local isDead = Types.Actor.isDead(self)
      if isDead then return end

      local isOnGround = Types.Actor.isOnGround(self)
      local isSwimming = Types.Actor.isSwimming(self)
      --Water splash sound
      local height = SoundPlayer.rayCastWater(self)
      if height and height > 0 and (lastWaterHeight == nil or lastWaterHeight <= 0) then
        if not isOnGround and not isSwimming then
          local waterHeight = SoundPlayer.getWaterDeepness(self)
          local pitch = 1.5 - (waterHeight / 100)
          SoundPlayer.playWaterSplash(self, pitch)
        end
      end
      lastWaterHeight = height

      --Landing sound
      if lastIsOnGround == false and isOnGround and not isSwimming then
        --print("Landing sound")
        local waterHeight, isInWater, distanceToWater = SoundPlayer.getWaterDeepness(self)
        if waterHeight and waterHeight > 0 and not isInWater and distanceToWater < 5 then
          SoundPlayer.playWaterSplash(self,3.0)
        elseif not isInWater or waterHeight < 50 then
          SoundPlayer.playLandingSound(self)
        end
        SoundPlayer.playFootstepSound(self)
        SoundPlayer.playArmorSound(self)
        lastIsOnGround = isOnGround
        return
      end
      lastIsOnGround = isOnGround

      --Stop sound
      local currentSpeed = Types.Actor.getCurrentSpeed(self)
      if lastSpeed > 0 and currentSpeed == 0 and isOnGround then
        SoundPlayer.playFootstepSound(self)
        SoundPlayer.playArmorSound(self)
        lastSpeed = 0
      end
      lastSpeed = currentSpeed

      --Moving sound
      if isMoving() and isOnGround then
        local footstepTime = calculateFootstepTime()
        if isBeast then
          footstepTime = calculateFootstepTime()
        end

        if isWalking() then
          footstepTime = calculateFootstepTime()
          if isBeast then
            footstepTime = calculateFootstepTime()
          end
        end

        if lastFootstepTime + footstepTime < Core.getSimulationTime() then
          lastFootstepTime = Core.getSimulationTime()
          SoundPlayer.playFootstepSound(self)
          SoundPlayer.playArmorSound(self)
        end
      else
        lastFootstepTime = Core.getSimulationTime()
      end
    end
  }
}