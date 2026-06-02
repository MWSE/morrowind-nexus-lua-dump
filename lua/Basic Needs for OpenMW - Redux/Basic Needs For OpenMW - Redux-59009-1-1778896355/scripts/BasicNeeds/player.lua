-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/player.lua
-- -----------------------------------------------------------------------------

local async = require("openmw.async")
local core = require("openmw.core")
local self = require("openmw.self")
local ui = require("openmw.ui")
local util = require("openmw.util")
local time = require("openmw_aux.time")
local nearby = require("openmw.nearby")
local camera = require("openmw.camera")
local ambient = require("openmw.ambient")

local settings = require("scripts.BasicNeeds.settings")
local State = require("scripts.BasicNeeds.state")
local HUD = require("scripts.BasicNeeds.hud")

local ACTION = require("openmw.input").ACTION
local L = core.l10n("BasicNeeds")

local sleepStartTime = 0
local isSleeping = false

-- -----------------------------------------------------------------------------
-- TU LISTA DE OBJETOS ESPECÍFICOS
-- -----------------------------------------------------------------------------
local WATER_SOURCES = {
    -- "ex_vivec_waterspout_02",
    -- "furn_moldcave_pool00",
}

-- -----------------------------------------------------------------------------
-- Initialization
-- -----------------------------------------------------------------------------
local UPDATE_INTERVAL = time.second * 10

-- Inicializar HUD con los settings actuales
local currentSettings = settings.getValues(settings.group)
HUD.init(currentSettings)

local state = State.new({
   previousTime = core.getGameTime(),
   previousCell = self.object.cell,
   wellRestedTime = nil,
   thirst = 0,
   hunger = 0,
   exhaustion = 0,
}, currentSettings)

local function onUpdate()
   state:update(core.getGameTime(), self.object.cell)
end

settings.group:subscribe(async:callback(function()
   local s = settings.getValues(settings.group)
   state:setSettings(s)
   HUD.applySettings(s)
end))

time.runRepeatedly(onUpdate, UPDATE_INTERVAL, { type = time.GameTime })

-- -----------------------------------------------------------------------------
-- Helper: detectar fuente de agua válida bajo el cursor
-- -----------------------------------------------------------------------------
local function isWaterSource(id)
   local lower = id:lower()
   if lower:find("_well") or lower:find("waterfall") or lower:find("spout") or lower:find("pool") then
      return true
   end
   for _, sourceId in ipairs(WATER_SOURCES) do
      if lower == sourceId:lower() then return true end
   end
   return false
end

-- -----------------------------------------------------------------------------
-- Engine/event handlers
-- -----------------------------------------------------------------------------
local function onFrame(dt)
   if core.isWorldPaused() or not state.thirst:isEnabled() then
      HUD.waterPrompt:hide()
      return
   end

   local pos = camera.getPosition()
   local dir = camera.viewportToWorldVector(util.vector2(0.5, 0.5))
   local raycast = nearby.castRay(pos, pos + dir * 150)

   if raycast.hitObject and raycast.hitObject.recordId and isWaterSource(raycast.hitObject.recordId) then
      HUD.waterPrompt:show()
   else
      HUD.waterPrompt:hide()
   end
end

local function onUiModeChange(data)
   local I = require("openmw.interfaces")

   if data.newMode ~= I.UI.MODE.Rest and data.oldMode ~= I.UI.MODE.Rest then
      return
   end

   if data.newMode == I.UI.MODE.Rest and not data.oldMode and not data.arg then
      isSleeping = false
   end

   if data.newMode == I.UI.MODE.Rest and not data.oldMode and not data.arg == false then
      sleepStartTime = core.getGameTime()
      isSleeping = true
   end

   if data.newMode == I.UI.MODE.Rest and sleepStartTime == 0 then
      sleepStartTime = core.getGameTime()
   end

   if data.oldMode == I.UI.MODE.Rest and not data.newMode then
      if sleepStartTime > 0 then
         local hoursPassed = (core.getGameTime() - sleepStartTime) / time.hour
         if hoursPassed > 0 then
            if isSleeping then
               state:applySleep(hoursPassed, core.getGameTime())
               ui.showMessage(string.format("You slept for %d hour(s).", math.floor(hoursPassed + 0.5)))
            else
               state:applyWait(hoursPassed, core.getGameTime())
               ui.showMessage(string.format("You waited for %d hour(s).", math.floor(hoursPassed + 0.5)))
            end
         end
      end
      sleepStartTime = 0
      isSleeping = false
   end
end

local function onLoad(data)
   local s = settings.getValues(settings.group)
   if data then
      state = State.deserialize(data, s)
   else
      state = State.new({
         previousTime = core.getGameTime(),
         previousCell = self.object.cell,
         wellRestedTime = nil,
         thirst = 0,
         hunger = 0,
         exhaustion = 0,
      }, s)
   end
   state._previousTime = core.getGameTime()
   HUD.applySettings(s)
   ui.updateAll()
end

local function isStandingInWater(actor)
   local cell = actor.cell
   return cell and cell.hasWater and actor.position.z < cell.waterLevel
end

local function onInputAction(action)
   if (core.isWorldPaused()) then return end

   if state.thirst:isEnabled() and action == ACTION.Activate then
      local pos = camera.getPosition()
      local dir = camera.viewportToWorldVector(util.vector2(0.5, 0.5))
      local raycast = nearby.castRay(pos, pos + dir * 150)

      if raycast.hitObject and raycast.hitObject.recordId then
         if isWaterSource(raycast.hitObject.recordId) then
            core.sendGlobalEvent("PlayerFillContainer", { player = self })
            return
         end
      end
   end

   if state.thirst:isEnabled() and action == ACTION.Sneak and isStandingInWater(self) then
      core.sendGlobalEvent("PlayerFillContainer", { player = self })
   end
end

local function playerConsumedFood(eventData)
   state.thirst:mod(eventData.thirst)
   state.hunger:mod(eventData.hunger)
   state.exhaustion:mod(eventData.exhaustion)
end

local function playerFilledContainer(eventData)
   if eventData.summary then
      ambient.playSound("Item Potion Up")
      for _, info in ipairs(eventData.summary) do
         if info.count > 1 then
            ui.showMessage(string.format("You filled %d %s with water.", info.count, info.name))
         else
            ui.showMessage(L("filledContainer", { item = info.name }))
         end
      end
   else
      if state.thirst:status() <= 1 then
         -- sin mensaje, el jugador no tiene sed
      else
         ambient.playSound("Drink")
         ui.showMessage("You drank a sip of water.")
         local s = settings.getValues(settings.group)
         state.thirst:mod(-s.drinkWaterThirstRestore)
      end
   end
end

return {
   interfaceName = "BasicNeeds",
   interface = {
      version = 1,
      getThirstStatus = function() return state.thirst:status() end,
      getHungerStatus = function() return state.hunger:status() end,
      getExhaustionStatus = function() return state.exhaustion:status() end,
   },
   engineHandlers = {
      onLoad = onLoad,
      onSave = function() return state:serialize() end,
      onConsume = function(item) core.sendGlobalEvent("PlayerConsumeItem", { player = self, item = item }) end,
      onInputAction = onInputAction,
      onFrame = onFrame,
   },
   eventHandlers = {
      PlayerConsumedFood = playerConsumedFood,
      PlayerFilledContainer = playerFilledContainer,
      UiModeChanged = onUiModeChange,
   },
}
