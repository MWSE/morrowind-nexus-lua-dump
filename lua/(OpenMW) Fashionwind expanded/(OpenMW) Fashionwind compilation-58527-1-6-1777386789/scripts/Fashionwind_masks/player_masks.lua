local self    = require('openmw.self')
local types   = require('openmw.types')
local anim    = require('openmw.animation')
local ui      = require('openmw.ui')
local async   = require('openmw.async')
local camera  = require('openmw.camera')
local storage = require('openmw.storage')
local input   = require('openmw.input')
local I       = require('openmw.interfaces')

local Actor = types.Actor
local MD    = { first = camera.MODE.FirstPerson, third = camera.MODE.ThirdPerson }

local maskSettings = storage.playerSection('Settings_tt_FashionMA')

local FROST_SPELL_ID    = "fx_frostshield"
local FIRE_SPELL_ID     = "fx_fireshield"
local CDISEASE_SPELL_ID = "fx_cdisres"
local BDISEASE_SPELL_ID = "fx_bdisres"
local POISON_SPELL_ID   = "fx_poisres"

local BUFF_SPELLS = {
    FROST_SPELL_ID,
    FIRE_SPELL_ID,
    CDISEASE_SPELL_ID,
    BDISEASE_SPELL_ID,
    POISON_SPELL_ID,
}

local function applyMaskBuffs(actor)
    if not maskSettings:get('MASKBUFFS') then return end
    for _, spellId in ipairs(BUFF_SPELLS) do
        -- your existing add-spell logic here, e.g.:
        -- actor:addSpell(spellId)
    end
end

local function removeMaskBuffs(actor)
    for _, spellId in ipairs(BUFF_SPELLS) do
        -- your existing remove-spell logic here, e.g.:
        -- actor:removeSpell(spellId)
    end
end

local cam     = camera.getMode()
local devMode = false

local VFX_ID   = 'visibleMasks'
local vfxMasks = { loop = true, useAmbientLight = false, vfxId = VFX_ID }

local masksListIndex = storage.playerSection('Settings_tt_masks_cycle')
local AheadBoneOwner = storage.playerSection('Settings_tt_mask')
local settingsMA     = storage.playerSection('Settings_tt_FashionMA')
local masksState     = storage.playerSection('Settings_tt_masks_state')

local function getMasksIndex()  return masksListIndex:get('cycleIndex') or 1 end
local function setMasksIndex(n) masksListIndex:set('cycleIndex', n) end

local function claimAHeadBone() AheadBoneOwner:set('owner', 'masks') end
local function AheadIsOurs()
  local owner = AheadBoneOwner:get('owner')
  return owner == nil or owner == 'masks'
end

local masksList = {
  'Ashmask1', 'Ashmask2', 'Ashmask3',
  'Daedramask1', 'Daedramask2', 'Daedramask3', 'Daedramask4',
  'Facewrap1', 'Facewrap2', 'Facewrap3', 'Facewrap4',
  'Facewrap5', 'Facewrap6', 'Facewrap7', 'Facewrap8',
  'Orcishmask1', 'Orcishmask2',
}

local function buildStemMap()
  local stemMap = {}
  for _, item in ipairs(Actor.inventory(self):getAll()) do
      local ok, rec = pcall(function() return item.type.records[item.recordId] end)
      if ok and rec and rec.model then
          local path = rec.model:lower()
          path = path:gsub('_gnd%.nif$', ''):gsub('%.nif$', '')
          local folder = path:match('^(.*[/\\])') or ''
          local fname  = path:match('([^/\\]+)$') or path
          stemMap[fname] = folder .. fname .. '_skins.nif'
      end
  end
  return stemMap
end

local function getAvailableMasks()
  local stemMap   = buildStemMap()
  local available = {}
  for _, stem in ipairs(masksList) do
      local skinsPath = stemMap[stem:lower()]
      if skinsPath then available[#available + 1] = { stem = stem, skins = skinsPath } end
  end
  return available
end

local showMasks          = masksState:get('showMasks') or false
--local CHMASKBUFFS		 = buffmasksState:get('MASKBUFFS') or false
local MasksKeyWasDown    = false
local MvariantKeyWasDown = false
local debounceCounter    = 0

local counter   = math.random(3, 20)
local refresh   = true
local newEquip  = false
local useHelper = false
local lastSkins = nil

local function setShowMasks(val)
  showMasks = val
  masksState:set('showMasks', val)
  if not val then
      Actor.spells(self):remove(FROST_SPELL_ID)
      Actor.spells(self):remove(FIRE_SPELL_ID)
      Actor.spells(self):remove(CDISEASE_SPELL_ID)
      Actor.spells(self):remove(BDISEASE_SPELL_ID)
      Actor.spells(self):remove(POISON_SPELL_ID)
  end
end

local function debug(m)
  if devMode then print(m); ui.showMessage(m) end
end

local function scanInv(reset)
  newEquip = false
  refresh  = false

  local availMasks  = getAvailableMasks()
  local mIdx        = getMasksIndex()
  if mIdx > #availMasks then mIdx = math.max(#availMasks, 1) end
  local activeSkins = availMasks[mIdx] and availMasks[mIdx].skins or nil

  local changed = (activeSkins ~= lastSkins) or reset
  if not changed then return end
  lastSkins = activeSkins

  debug('masks: remove vfx')
  anim.removeVfx(self, VFX_ID)

  local vfxActive = showMasks and activeSkins and cam ~= MD.first and AheadIsOurs()

    if vfxActive then
      debug('masks vfx: ' .. activeSkins)
      vfxMasks.boneName = 'head'
      anim.addVfx(self, activeSkins, vfxMasks)
      if maskSettings:get('MASKBUFFS') then
          Actor.spells(self):add(FROST_SPELL_ID)
          Actor.spells(self):add(FIRE_SPELL_ID)
          Actor.spells(self):add(CDISEASE_SPELL_ID)
          Actor.spells(self):add(BDISEASE_SPELL_ID)
          Actor.spells(self):add(POISON_SPELL_ID)
      end
  else
      Actor.spells(self):remove(FROST_SPELL_ID)
      Actor.spells(self):remove(FIRE_SPELL_ID)
      Actor.spells(self):remove(CDISEASE_SPELL_ID)
      Actor.spells(self):remove(BDISEASE_SPELL_ID)
      Actor.spells(self):remove(POISON_SPELL_ID)
  end
end

local function onFrame(dt)
  if debounceCounter > 0 then
      debounceCounter = debounceCounter - 1
      return
  end

--  local showKeyCode   = settingsMA:get('MAShow')
--  local changeKeyCode = settingsMA:get('MAChange')

--  local mVarKeyDown = showKeyCode   and input.isKeyPressed(showKeyCode)   or false
--  local keyDown     = changeKeyCode and input.isKeyPressed(changeKeyCode) or false
  
  local mVarKeyDown = input.getBooleanActionValue('MAShow')
  if mVarKeyDown and not MvariantKeyWasDown then
      setShowMasks(not showMasks)
      if showMasks then claimAHeadBone() end
      counter = 1
      refresh = true
      debounceCounter = 0
      debug('Masks VFX: ' .. (showMasks and 'ON' or 'OFF'))
  end
  MvariantKeyWasDown = mVarKeyDown

  local keyDown = input.getBooleanActionValue('MAChange')
  if keyDown and not MasksKeyWasDown then
      local availMasks = getAvailableMasks()
      if #availMasks > 0 then
          setShowMasks(true)
          claimAHeadBone()
          local cur = getMasksIndex()
          if cur > #availMasks then cur = #availMasks end
          local nxt = cur % #availMasks + 1
          setMasksIndex(nxt)
          counter = 1
          refresh = true
          debounceCounter = 15
          debug('Masks: ' .. availMasks[nxt].stem .. ' (' .. nxt .. '/' .. #availMasks .. ')')
      else
          debug('Masks: none available in inventory')
      end
  end
  MasksKeyWasDown = keyDown

  if newEquip then scanInv(refresh) end
  counter = counter - 1
  if counter > 0 then return end
  counter = 20
  if refresh or not useHelper then scanInv(refresh) end
end

local function onUpdate(dt)
  if dt == 0 then return end
  if cam == camera.getMode() then return end
  local mode, fp = camera.getMode(), MD.first
  if mode == fp or cam == fp then
      cam = mode
      counter = 3
      refresh = true
  end
  cam = mode
end

local function onActive()
  counter = 3
  refresh = true
end

return {
  engineHandlers = { onUpdate = onUpdate, onFrame = onFrame, onActive = onActive },
  eventHandlers  = {
      UiModeChanged = function(e)
          local uiModes = {
              [I.UI.MODE.Rest]     = true,
              [I.UI.MODE.Training] = true,
              [I.UI.MODE.Travel]   = true,
          }
          if uiModes[e.oldMode] then
              counter = 3
              refresh = true
          end
      end,
      olhInitialized = function()
          useHelper = true
          I.luaHelper.eventRegister('equipped',   function() newEquip = true end)
          I.luaHelper.eventRegister('unequipped', function() newEquip = true end)
      end,
      vfxRemoveAll = function()
          counter = math.random(11, 16)
          refresh = true
      end,
  },
}