local core = require('openmw.core')
local storage = require('openmw.storage')

local settings = storage.globalSection('SettingsImbuleWeapon')

local function handleNewSpell(data)
  local storageData = storage.globalSection('IW_ActiveSpell')
  if settings:get("SpellStacking") and settings:get('CastMethod') == "Charges" and storageData ~= nil then
    local spell = storageData:getCopy('activeSpell')
    if spell ~= nil then
      if spell.id == data.spell.id then
--        print("Spell is the same")
        spell.charges = spell.charges + data.spell.charges
        storageData:set('activeSpell',spell)
--        print("New charges:",storage.globalSection('IW_ActiveSpell'):get('activeSpell').charges)
      else
        storageData:set('activeSpell',data.spell)
--        print("Set spell:",data.spell.name)
--        print("With charges:",data.spell.charges)
      end
    else
      storageData:set('activeSpell',data.spell)
--      print("Set spell:",data.spell.name)
--      print("With charges:",data.spell.charges)
    end
  else
    storageData:set('activeSpell',data.spell)
--    print("Set spell:",data.spell.name)
--    print("With charges:",data.spell.charges)
  end
end

local function decrementSpellCharge(data)
  local storageData = storage.globalSection('IW_ActiveSpell')
  local spell = storageData:getCopy('activeSpell')
--  print(data.firstUse)
  if data.firstUse == nil and spell ~= nil then
    if spell.charges > 0 then
--        print("Decrementing charge:")
        spell.charges = spell.charges-1
--        print("Remaining charges:",storageData:get('activeSpell').charges)
        if spell.charges == 0 then
--          print("Charge reached 0, removing spell")
          storageData:reset('activeSpell')
          return
        end
        storageData:set('activeSpell',spell)
--        print("Remaining charges:",storageData:get('activeSpell').charges)
      else
--        print("Ran out of charges!")
--        print("Removing spell")
        storageData:reset('activeSpell')
    end
  else
    if spell ~= nil then
      local firstUse = data.firstUse
      spell.firstUse = firstUse
      storageData:set('activeSpell',spell)
    end
  end
end

local function removeSpell()
  storage.globalSection('IW_ActiveSpell'):reset('activeSpell')
end

local function saveSpell()
  local storageData = storage.globalSection('IW_ActiveSpell')
  if storageData ~= nil then
    local spell = storageData:getCopy('activeSpell')
    if spell ~= nil then
      local savedData = {
        spellId = spell.id,
        name = spell.name,
        charges = spell.charges,
        firstUse = spell.firstUse
      }
      return savedData
    end
  end
end

local function loadSpell(savedData)
  storage.globalSection('IW_ActiveSpell'):reset('activeSpell')
  if savedData ~= nil then
    if savedData.spellId ~= nil then
      local spell = {
        id = savedData.spellId,
        name = savedData.name,
        charges = savedData.charges,
        firstUse = savedData.firstUse,
      }
      storage.globalSection('IW_ActiveSpell'):set('activeSpell',spell)
    end
  end
end

local function onInit()
  storage.globalSection('IW_ActiveSpell'):reset('activeSpell')
end

return  {
  eventHandlers = {
    IW_SpellCast = handleNewSpell,
    IW_DecrementSpellCharge = decrementSpellCharge,
    IW_RemoveSpell = removeSpell,
  },
  engineHandlers = {
  onSave = saveSpell,
  onLoad = loadSpell,
  onInit = onInit,
  }
}