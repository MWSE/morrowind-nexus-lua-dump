--[[
Just Simply Magicka Regeneration for OpenMW
by frogstat ( https://www.nexusmods.com/profile/frogstat )
]] --

local self = require('openmw.self')
local core = require('openmw.core')
local types = require('openmw.types')
local storage = require("openmw.storage")

require('scripts.JustSimplyMagickaRegen.settings')
local settings = storage.playerSection('SettingsJustSimplyMagickaRegen')


local lastRegenTime = 0
local magickaDuringLastLoop = 0
local magickaLossTime = 0

local function getPlayerMaxMagicka()
  local stat = types.Player.stats.dynamic.magicka(self)
  return stat.base + stat.modifier
end

local function getPlayerCurrentMagicka()
  return types.Player.stats.dynamic.magicka(self).current
end

-- Added a equal or greater than, just in case, but it should never go beyond max.
local function playerIsAtMaxMagicka()
  return getPlayerCurrentMagicka() >= getPlayerMaxMagicka()
end

local function addMagicka(amountToAdd)
  local current = getPlayerCurrentMagicka()
  local max = getPlayerMaxMagicka()
  local newValue = current + amountToAdd

  if newValue > max then
    newValue = max
  end

  types.Player.stats.dynamic.magicka(self).current = newValue
end

-- This will not work if timescale is set to 0 (which you should never do anyway), as the game won't register any passage of time.
local function getCurrentTime()
  local timescale = core.getGameTimeScale()

  if timescale == 0 then
    return 0
  end

  return core.getGameTime() / core.getGameTimeScale()
end

local function waitAmount()
  -- This can max be 10, otherwise it can have inconsistent behavior on low framerates (not to mention extremely unbalanced.)
  local regenRate = settings:get('magicka_per_second')

  if regenRate == 0 then
    return -1
  end

  return 1 / regenRate
end

-- time between each point of magicka given
local function enoughTimeHasPassedRegen(currentTime)
  if lastRegenTime == 0 then
    return true
  end

  local waitAmountResult = waitAmount()
  if waitAmountResult == -1 then
    return false
  end

  return currentTime >= lastRegenTime + waitAmountResult
end

local function playerHasLostMagicka()
  return getPlayerCurrentMagicka() < magickaDuringLastLoop
end


-- Time between losing magicka and regeneration beginnning.
local function enoughTimeHasPassedDelay(currentTime)
  local delayAmount = settings:get('delay_before_regeneration')

  if delayAmount == 0 then
    return true
  end

  return currentTime >= magickaLossTime + delayAmount
end


local function onUpdate()


  if types.Player.getBirthSign(self) == "wombburned" then
    -- wombburned means Atronach birthsign
    -- pick a different birthsign or find another mod, cheater :)
    return
  end

  -- Will not regenerate if you're already at max.
  if not playerIsAtMaxMagicka() then

    local currentTime = getCurrentTime()

    -- This is needed for the regen delay to work.
    if playerHasLostMagicka() then
      magickaLossTime = currentTime
    end

    -- Once the delay has expired, you can finally regenerate. If delay is set to 0, this will always be true.
    if enoughTimeHasPassedDelay(currentTime) then

      -- This is the time between each point of magicka given to the player. How much the wait time is depends on the regen rate.
      if enoughTimeHasPassedRegen(currentTime) then
        addMagicka(1)
        lastRegenTime = currentTime
      end

    end
  end

  -- This is needed for playerHasLostMagicka() to work, it can't know if you've lost magicka unless the previous value is cached.
  magickaDuringLastLoop = getPlayerCurrentMagicka()
end

return {
  engineHandlers = {
    onUpdate = onUpdate
  }
}
