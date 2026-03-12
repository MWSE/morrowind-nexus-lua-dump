-- scripts/devilish_skooma_global.lua
-- Global: intercept pipe use (drag-drop) + consume moon sugar + tell player script to smoke.
-- Also receives time-scale changes from local script.

local core  = require('openmw.core')
local world = require('openmw.world')
local types = require('openmw.types')
local I     = require('openmw.interfaces')

-- Pipe record(s) that should trigger smoking when "used"
local PIPE_RECORDS = {
  ['apparatus_a_spipe_01'] = true, -- vanilla pipe
}

local MOON_SUGAR = 'ingred_moon_sugar_01'

-- Your bong sound (VFS path)
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
    return false -- block default use
  end

  -- Consume 1 moon sugar using built-in global event
  local sugarItem = inv:find(MOON_SUGAR)
  if sugarItem then
    core.sendGlobalEvent('ConsumeItem', { item = sugarItem, amount = 1 })
  end

  -- Tell player-local script to play animation/vfx/sound + add dose
  actor:sendEvent('DETD_SkoomaPipeSmoked', {
    soundFile = BONG_SOUND,
  })

  return false
end

I.ItemUsage.addHandlerForType(types.Apparatus, onUseItem)

-- time scale handler from local script
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