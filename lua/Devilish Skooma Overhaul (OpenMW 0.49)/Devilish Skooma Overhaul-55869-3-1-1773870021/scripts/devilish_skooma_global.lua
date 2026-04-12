-- scripts/devilish_skooma_global.lua
-- Global: intercept pipe use + consume moon sugar + tell player-local script to add a dose.
-- Also applies time-scale changes from the player-local script.

local core  = require('openmw.core')
local world = require('openmw.world')
local types = require('openmw.types')
local I     = require('openmw.interfaces')

local PIPE_RECORDS = {
  ['apparatus_a_spipe_01'] = true,
}

local MOON_SUGAR = 'ingred_moon_sugar_01'
local BONG_SOUND = 'Sound\\detd_Bongsound.wav'

local function getPlayer()
  return world.players and world.players[1]
end

local function onUseItem(obj, actor, options)
  if not obj or not actor or not actor:isValid() then return end

  local player = getPlayer()
  if not player or actor ~= player then return end

  local rid = (obj.recordId or ''):lower()
  if not PIPE_RECORDS[rid] then return end

  local inv = types.Actor.inventory(actor)
  if inv:countOf(MOON_SUGAR) < 1 then
    actor:sendEvent('ShowMessage', { message = 'You have no Moonsugar.' })
  --  print('debugmsg [skooma_global] pipe use blocked: no moon sugar')
    return false
  end

  local sugarItem = inv:find(MOON_SUGAR)
  if sugarItem then
    core.sendGlobalEvent('ConsumeItem', { item = sugarItem, amount = 1 })
   -- print('debugmsg [skooma_global] consumed 1 moon sugar from pipe use')
  end

  actor:sendEvent('DETD_SkoomaPipeSmoked', {
    soundFile = BONG_SOUND,
  })

  return false
end

I.ItemUsage.addHandlerForType(types.Apparatus, onUseItem)

local function skoomaSetTimeScale(scale)
  if scale < 0.1 then scale = 0.1 end
  if scale > 2.0 then scale = 2.0 end
  world.setSimulationTimeScale(scale)
end

return {
  eventHandlers = {
    skoomaSetTimeScale = skoomaSetTimeScale
  }
}
