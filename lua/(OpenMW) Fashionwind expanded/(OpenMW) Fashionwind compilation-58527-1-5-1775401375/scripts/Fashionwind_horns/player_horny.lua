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

local hornsSettings = storage.playerSection('Settings_tt_fashionwindANTL')

local BEAUT_SPELL_ID    = "fx_beautyh"

local BUFF_SPELLS = {
    BEAUT_SPELL_ID,
}

local function applyHornsBuffs(actor)
    if not hornsSettings:get('HORBUFFS') then return end
    for _, spellId in ipairs(BUFF_SPELLS) do
		Actor.spells(actor):add(spellId)
    end
end

local function removeHornsBuffs(actor)
    for _, spellId in ipairs(BUFF_SPELLS) do
		Actor.spells(actor):remove(spellId)
    end
end

local cam     = camera.getMode()
local devMode = false

local VFX_ID   = 'visibleHorns'
local vfxHorns = { loop = true, useAmbientLight = false, vfxId = VFX_ID }

local HornsListIndex = storage.playerSection('Settings_tt_horns_cycle')
local CheadBoneOwner    = storage.playerSection('Settings_tt_horns')
local settingsHOR        = storage.playerSection('Settings_tt_fashionwindANTL')
local FWhornsState      = storage.playerSection('Settings_tt_horns_state')

local function getHornsIndex()  return HornsListIndex:get('cycleIndex') or 1 end
local function setHornsIndex(n) HornsListIndex:set('cycleIndex', n) end

local function claimCHeadBone() CheadBoneOwner:set('owner', 'horns') end
local function CheadIsOurs()
  local owner = CheadBoneOwner:get('owner')
  return owner == nil or owner == 'horns'
end

local hornsList = {
  'antlers1', 'antlers2', 'ears1',
   'ears2', 'horns1', 'horns2', 'horns3', 
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

local function getAvailableHorns()
  local stemMap   = buildStemMap()
  local available = {}
  for _, stem in ipairs(hornsList) do
      local skinsPath = stemMap[stem:lower()]
      if skinsPath then available[#available + 1] = { stem = stem, skins = skinsPath } end
  end
  return available
end

local showhorns          = FWhornsState:get('showhorns') or false
local hornsKeyWasDown    = false
local HORvariantKeyWasDown = false
local debounceCounter    = 0

local counter   = math.random(3, 20)
local refresh   = true
local newEquip  = false
local useHelper = false
local lastSkins = nil

local function setShowhorns(val)
  showhorns = val
  FWhornsState:set('showhorns', val)
  if not val then
      Actor.spells(self):remove(BEAUT_SPELL_ID)
  end
end

local function debug(m)
  if devMode then print(m); ui.showMessage(m) end
end

local function scanInv(reset)
  newEquip = false
  refresh  = false

  local availhorns      = getAvailableHorns()
  local horIdx          = getHornsIndex()
  if horIdx > #availhorns then horIdx = math.max(#availhorns, 1) end
  local activeSkins = availhorns[horIdx] and availhorns[horIdx].skins or nil

  local changed = (activeSkins ~= lastSkins) or reset
  if not changed then return end
  lastSkins = activeSkins

  debug('horns: remove vfx')
  anim.removeVfx(self, VFX_ID)

  local vfxActive = showhorns and activeSkins and cam ~= MD.first and CheadIsOurs()

    if vfxActive then
      debug('horns vfx: ' .. activeSkins)
      vfxHorns.boneName = 'head'
      anim.addVfx(self, activeSkins, vfxHorns)
      if hornsSettings:get('HORBUFFS') then
          Actor.spells(self):add(BEAUT_SPELL_ID)
      end
  else
      Actor.spells(self):remove(BEAUT_SPELL_ID)
  end
end

local function onFrame(dt)
  if debounceCounter > 0 then
      debounceCounter = debounceCounter - 1
      return
  end

  local showKeyCode   = settingsHOR:get('HORShow')
  local changeKeyCode = settingsHOR:get('HORChange')

  local horVarKeyDown = showKeyCode   and input.isKeyPressed(showKeyCode)   or false
  local keyDown       = changeKeyCode and input.isKeyPressed(changeKeyCode) or false

  if horVarKeyDown and not HORvariantKeyWasDown then
      setShowhorns(not showhorns)
      if showhorns then claimCHeadBone() end
											  
      counter = 1
      refresh = true
      debounceCounter = 0
      debug('horns VFX: ' .. (showhorns and 'ON' or 'OFF'))
  end
  HORvariantKeyWasDown = horVarKeyDown

  if keyDown and not hornsKeyWasDown then
      local availhorns = getAvailableHorns()
      if #availhorns > 0 then
          setShowhorns(true)
          claimCHeadBone()
          local cur = getHornsIndex()
          if cur > #availhorns then cur = #availhorns end
          local nxt = cur % #availhorns + 1
          setHornsIndex(nxt)
          counter = 1
          refresh = true
          debounceCounter = 15
          debug('horns: ' .. availhorns[nxt].stem .. ' (' .. nxt .. '/' .. #availhorns .. ')')
      else
          debug('horns: none available in inventory')
      end
  end
  hornsKeyWasDown = keyDown

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