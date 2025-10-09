-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/player.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com> (original author)
-- 2025 -- Modified by DetailDevil for Devilish Needs 
-- -----------------------------------------------------------------------------
local async       = require("openmw.async")
local core        = require("openmw.core")
local self        = require("openmw.self")
local ui          = require("openmw.ui")
local time        = require("openmw_aux.time")
local types       = require('openmw.types')

local bed         = require("scripts.BasicNeeds.bed")
local settings    = require("scripts.BasicNeeds.settings")
local State       = require("scripts.BasicNeeds.state")
local showImage   = require("scripts.BasicNeeds.showIcon")
local showImage2  = require("scripts.BasicNeeds.showIcon2")
local showImage3  = require("scripts.BasicNeeds.showIcon3")
local showImage4  = require("scripts.BasicNeeds.showIcon4")

local Actor       = types.Actor
local ACTION      = require("openmw.input").ACTION
local L           = core.l10n("BasicNeeds")
local hud         = require("scripts.BasicNeeds.hud")

-- -----------------------------------------------------------------------------
-- Initialization
-- -----------------------------------------------------------------------------
local UPDATE_INTERVAL = time.second * 10

local state = State.new({
   previousTime    = core.getGameTime(),
   previousCell    = self.object.cell,
   wellRestedTime  = nil,
   thirst          = 0,
   hunger          = 0,
   exhaustion      = 0,
   coldness        = 0,
   wet             = 0,
}, settings.getValues(settings.group))

-- When settings change: update state and reposition all icons
local function onSettingsUpdate()
   local cfg = settings.getValues(settings.group)
   state:setSettings(cfg)
   -- recalc and redraw each icon immediately
   showImage()
   showImage2()
   showImage3()
   showImage4()
end
settings.group:subscribe(async:callback(onSettingsUpdate))

-- Periodic world-time updates for core state
local function onUpdate()
   state:update(core.getGameTime(), self.object.cell)
end
time.runRepeatedly(onUpdate, UPDATE_INTERVAL, { type = time.GameTime })

-- -----------------------------------------------------------------------------
-- Engine/event handlers
-- -----------------------------------------------------------------------------
local function onLoad(data)
   state = State.deserialize(data, settings.getValues(settings.group))
  -- ui.updateAll()
   Actor.inventory(self):getAll()  -- normalize potions
end

local function onSave() return state:serialize() end

local function onConsume(item)
   core.sendGlobalEvent("PlayerConsumeItem", { player = self, item = item })
end

local function onInputAction(action)
   if core.isWorldPaused() then return end
   if state.exhaustion:isEnabled() and action == ACTION.Activate then
      state:setSleepingInBed(bed.tryFindBed(self))
   end
end

local function playerConsumedFood(eventData)
   state.thirst:mod(eventData.thirst)
   state.hunger:mod(eventData.hunger)
   state.exhaustion:mod(eventData.exhaustion)
end

local function playerFilledContainer(eventData)
   if eventData.containerName then
      --ui.showMessage(L("filledContainer", { item = eventData.containerName }))
   else
      --ui.showMessage(L("noContainers"))
      Actor.spells(self):add('detd_fillwaterbottlesfail')
   end
end

-- -----------------------------------------------------------------------------
-- HUD Icons and status updates
-- -----------------------------------------------------------------------------
local function updateStatuses()
   local spells = Actor.activeSpells(self)
   -- coldness
   for id, lvl in pairs({ aaj_dying=5, aaj_freezing=5, aak_very_cold=4, aal_cold=3, aap_chilly=2 }) do
      if spells:isSpellActive(id) then hud.coldness:update(lvl) break end
   end
   -- wetness
   for id, lvl in pairs({ aac_Soaked=5, aab_Wet=3, aaa_Damp=2 }) do
      if spells:isSpellActive(id) then hud.wet:update(lvl) break end
   end
   -- exhaustion status effect
   if spells:isSpellActive("A_Well_Rested") then hud.exhaustion:update(1) end
   -- firepit clears
   if spells:isSpellActive("aaaa_firepit") then
      hud.coldness:update(1); hud.wet:update(1)
      for _, id in ipairs({ 'aab_Wet','aac_Soaked','aaa_Damp','aal_cold','aak_very_cold','aap_chilly','aaj_freezing','aaj_dying'}) do
         Actor.spells(self):remove(id)
      end
   end
end


local function checkForMeatEffects()
   local myRace = self.type.records[self.recordId].race
   local active = types.Actor.activeSpells(self)
   for _, spell in pairs(active) do
       if spell.name and string.find(string.lower(spell.name), "meat") and myRace ~= "wood elf" then
         print(myRace)
           print("Player consumed raw meat:", spell.name)
           Actor.spells(self):add('dampworm')
           elseif spell.name and string.find(string.lower(spell.name), "cooking pot")  then
           -- You could call a custom function here instead of just printing
           Actor.spells(self):add('swamp fever')
       end
   end
end

-- Main repeating tick: update statuses and icons
time.runRepeatedly(function()
   checkForMeatEffects()
   updateStatuses()

   if (state.thirst:isEnabled() and Actor.activeSpells(self):isSpellActive("detd_fillwaterbottles") ) then
      
      core.sendGlobalEvent("PlayerFillContainer", {
         player = self,
      })
   
   end

 

   showImage(); showImage2(); showImage3(); showImage4()
end, 1 * time.second)

-- -----------------------------------------------------------------------------
-- Return script interface
-- -----------------------------------------------------------------------------
return {
   interfaceName = "BasicNeeds",
   interface = {
      version = 1,
      getThirstStatus     = function() return state.thirst:status() end,
      getHungerStatus     = function() return state.hunger:status() end,
      getExhaustionStatus = function() return state.exhaustion:status() end,
      getColdnessStatus   = function() return state.coldness:status() end,
      getWetStatus        = function() return state.wet:status() end,
   },
   engineHandlers = {
      onLoad        = onLoad,
      onSave        = onSave,
      onConsume     = onConsume,
      onInputAction = onInputAction,
   },
   eventHandlers = {
      PlayerConsumedFood    = playerConsumedFood,
      PlayerFilledContainer = playerFilledContainer,
   },
}
