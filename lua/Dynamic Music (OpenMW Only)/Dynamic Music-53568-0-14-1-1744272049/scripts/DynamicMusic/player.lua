local Globals = require('scripts.DynamicMusic.core.Globals')
local core = require('openmw.core')

if core.API_REVISION < Globals.LUA_API_REVISION_MIN then
  return nil
end

local ambient = require('openmw.ambient')
local self = require('openmw.self')
local storage = require('openmw.storage')

local GlobalData = require('scripts.DynamicMusic.core.GlobalData')
local Log = require('scripts.DynamicMusic.core.Logger')
local Context = require('scripts.DynamicMusic.core.Context')
local DynamicMusic = require('scripts.DynamicMusic.core.DynamicMusic')

---@type Context
local context

---@type DynamicMusic
local dynamicMusic

local initialized = false

local function initialize()
  if not initialized then
    context = Context.Create(self, ambient)

    dynamicMusic = DynamicMusic.Create(context)
    dynamicMusic:initialize()
    initialized = true

    local omwMusicSettings = storage.playerSection('SettingsOMWMusic')
    if omwMusicSettings then
      Log.info("changing built in openmw combat music setting to false")
      omwMusicSettings:set("CombatMusicEnabled", false)
    end
  end
end

local function onFrame(dt)
  if not initialized then
    return
  end

  context.gameState:update(dt)
  dynamicMusic:update(dt)

end

local function engaging(eventData)
  if (not eventData.actor) then
    return
  end

  if not eventData.targetActor or eventData.targetActor.id ~= self.id then
    return
  end

  GlobalData.hostileActors[eventData.actor.id] = eventData;
  --  print("engaging: " ..eventData.actor.id .." - " ..eventData.actor.recordId ..eventData.name)
end

local function disengaging(eventData)
  if (not eventData.actor) then return end;

  GlobalData.hostileActors[eventData.actor.id] = nil;
end

local function globalDataCollected(eventData)
  local data = eventData.data

  GlobalData.cellNames = data.cellNames
  GlobalData.regionNames = data.regionNames

  initialize()
end

return {
  engineHandlers = {
    onFrame = onFrame
  },
  eventHandlers = {
    engaging = engaging,
    disengaging = disengaging,
    globalDataCollected = globalDataCollected
  },
}
