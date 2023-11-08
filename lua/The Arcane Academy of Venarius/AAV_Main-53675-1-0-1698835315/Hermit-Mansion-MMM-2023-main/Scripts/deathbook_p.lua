local core = require('openmw.core')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local UI = require('openmw.interfaces').UI
local util = require('openmw.util')

local oneChance = false
local warnOnce = false
local stats = types.Actor.stats
local skills = types.NPC.stats.skills

local function handleDeathBook(uiData)

  if uiData.newMode ~= "Book" or not uiData.arg or uiData.arg.recordId ~= "aav_deathbook" then return end
    local alteration = skills['alteration'](self).base
    local intelligence = stats.attributes['intelligence'](self).base
    local personality = stats.attributes['personality'](self).base

  if uiData.arg.cell then
    UI.setMode()

    core.sendGlobalEvent('addDeathBook', { player = self.object, object = uiData.arg })

    if warnOnce then return end

    if intelligence <= 20 then
      ui.showMessage("This book looks like it has funny pictures in it. I should read it.")
    elseif personality <= 40 then
      ui.showMessage("Reminds me of the self-help books in the Vivec Library.")
    elseif alteration <= 40 and alteration >= 30 then
      ui.showMessage("This book is cursed. I'm not sure what exactly it is . . . but I don't think I want to find out.")
    elseif intelligence <= 40 and intelligence > 20 then
      ui.showMessage("Something about this book makes my skin crawl.")
    -- elseif --met venarius
    -- ui.showMessage("It seems Master Venarius placed a curse on this book to kill its reader. Perhaps I could use this to my advantage . . .")
    elseif alteration >= 75 or intelligence >= 90 then
      ui.showMessage("Someone placed a curse on this book to kill its reader. I'm not sure what I should do with this.")
    end

    warnOnce = true

  elseif not oneChance then
    UI.setMode()
    oneChance = true
    if intelligence <= 20 then
      ui.showMessage("Oooh! It was a little hard to open . . . But super shiny")
    elseif personality <= 40 then
      ui.showMessage("Maybe people would like me better if I read this book.")
    elseif alteration <= 40 and alteration >= 30 then
      ui.showMessage("I've managed to break the magical seal on the book. It feels heavier in my hands now, and I can feel it reaching out to me. I should leave this thing alone.")
    elseif intelligence <= 40 and intelligence > 20 then
      ui.showMessage("I can at least tell how to open it, but I don't think I should.")
    elseif alteration >= 75 or intelligence >= 90 then
      ui.showMessage("I don't see any reason to kill myself with a silly book like this.")
    end
  else
    UI.setMode()
    types.Actor.stats.dynamic["health"](self).current = 0
  end
end

local function gilHandler()
      if self.cell.name ~= 'HM Realm Fire and Ice' then return end

      local object = nearby.getObjectByFormId(core.getFormId('AAV_Giglndil.omwaddon', 3)) -- Update this post-merge; this is the gilFrozen object
      local distance = (self.position - object.position):length()
      local spell = types.Actor.getSelectedEnchantedItem(self)

      if types.Actor.stance(self) ~= types.Actor.STANCE.Spell or
        not spell or
        self.controls.use ~= 1
      then return end

      if spell.recordId ~= "aav_inspiregil" and spell.recordId ~= "aav_inspiregilstrong" then return end

      if distance > 150 then
        self.controls.use = 0
        ui.showMessage("I should only use this to save Gilgindil.")
      else
        core.sendGlobalEvent('spawnGil', {player = self,
                                          marbleCount = 0,
                                          gil = object,
                                          strength = spell.recordId == "aav_inspiregilstrong"})
      end
end

return {
  engineHandlers = {
    onUpdate = function ()
      gilHandler()
    end
  },

  eventHandlers = {
    UiModeChanged = handleDeathBook,
  }
}
