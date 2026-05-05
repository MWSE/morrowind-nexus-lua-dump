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

local headgearSettings = storage.playerSection('Settings_tt_fashionwindHG')

local BEAUT_SPELL_ID    = "fx_beautyc"

local BUFF_SPELLS = {
    BEAUT_SPELL_ID,
}

local function applyHeadgearBuffs(actor)
    if not headgearSettings:get('HGBUFFS') then return end
    for _, spellId in ipairs(BUFF_SPELLS) do
        Actor.spells(actor):add(spellId)
    end
end

local function removeHeadgearBuffs(actor)
    for _, spellId in ipairs(BUFF_SPELLS) do
        Actor.spells(actor):remove(spellId)
    end
end

local cam     = camera.getMode()
local devMode = false

local VFX_ID   = 'visibleHeadgear'
local vfxHeadgear = { loop = true, useAmbientLight = false, vfxId = VFX_ID }

local HeadgearListIndex = storage.playerSection('Settings_tt_headgear_cycle')
local GheadBoneOwner    = storage.playerSection('Settings_tt_headgear')
local settingsHG        = storage.playerSection('Settings_tt_fashionwindHG')
local FWheadgearState   = storage.playerSection('Settings_tt_headgear_state')

local function getHeadgearIndex()  return HeadgearListIndex:get('cycleIndex') or 1 end
local function setHeadgearIndex(n) HeadgearListIndex:set('cycleIndex', n) end
local function claimAHeadBone() GheadBoneOwner:set('owner', 'headgear') end
local function GheadIsOurs()
  local owner = GheadBoneOwner:get('owner')
  return owner == nil or owner == 'headgear'
end

local headgearList = {
   'BandCopper', 'BandGold', 'BandMithril', 'BandOrc', 'ChainBlack_Gems', 'ChainBlack', 'ChainGold', 'ChainGold_Gems', 'ChainSilver_Gems', 'ChainSilver', 'CircletBBlue', 'CircletBGreen', 'CircletBPearl', 'CircletBred', 'CircletBTopaz', 'CircletGBlue', 'CircletGGreen', 'CircletGPearl', 'CircletGRed', 'CircletGTopaz', 'CircletSBlue', 'CircletSgreen', 'CircletSPearl', 'CircletSRed', 'CircletSTopaz', 'CrownCeltic', 'CrownCross', 'CrownLeather', 'DiaGDia', 'DiaGEm', 'DiaGRu', 'DiaGSa', 'DiaG', 'DiaSDia', 'DiaSEm', 'DiaSRu', 'DiaSSa', 'DiaS', 'elvDia', 'elvEm', 'elvRu', 'twinS', 'twin', 'WEDia', 'WEGreen', 'WERed', 'slcirclet',
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

local function getAvailableHeadgear()
  local stemMap   = buildStemMap()
  local available = {}
  for _, stem in ipairs(headgearList) do
      local skinsPath = stemMap[stem:lower()]
      if skinsPath then available[#available + 1] = { stem = stem, skins = skinsPath } end
  end
  return available
end

local showheadgear          = FWheadgearState:get('showheadgear') or false
local headgearKeyWasDown    = false
local HGvariantKeyWasDown = false
local debounceCounter    = 0

local counter   = math.random(3, 20)
local refresh   = true
local newEquip  = false
local useHelper = false
local lastSkins = nil

local function setShowheadgear(val)
  showheadgear = val
  FWheadgearState:set('showheadgear', val)
  local availheadgear = getAvailableHeadgear()

  if val and #availheadgear > 0 and headgearSettings:get('HGBUFFS') then
      applyHeadgearBuffs(self)  
  else
      removeHeadgearBuffs(self) 
  end
end

local function debug(m)
  if devMode then print(m); ui.showMessage(m) end
end

local function scanInv(reset)
  newEquip = false
  refresh  = false

  local availheadgear  = getAvailableHeadgear()
  local hgIdx          = getHeadgearIndex()
  if hgIdx > #availheadgear then hgIdx = math.max(#availheadgear, 1) end
  local activeSkins = availheadgear[hgIdx] and availheadgear[hgIdx].skins or nil

  local changed = (activeSkins ~= lastSkins) or reset
  if not changed then return end
  lastSkins = activeSkins

  debug('headgear: remove vfx')
  anim.removeVfx(self, VFX_ID)

  local vfxActive = showheadgear and activeSkins and cam ~= MD.first and GheadIsOurs()


  if vfxActive then
      debug('headgear vfx: ' .. activeSkins)
      vfxHeadgear.boneName = 'head'
      anim.addVfx(self, activeSkins, vfxHeadgear)
  end
end

local function onFrame(dt)
  if debounceCounter > 0 then
      debounceCounter = debounceCounter - 1
      return
  end

--  local showKeyCode   = settingsHG:get('HGShow')
--  local changeKeyCode = settingsHG:get('HGChange')

-- local hgVarKeyDown = showKeyCode   and input.isKeyPressed(showKeyCode)   or false
--  local keyDown     = changeKeyCode and input.isKeyPressed(changeKeyCode) or false
  local hgVarKeyDown = input.getBooleanActionValue('HGShow')
  if hgVarKeyDown and not HGvariantKeyWasDown then
      setShowheadgear(not showheadgear)
      if showheadgear then claimAHeadBone() end
      counter = 1
      refresh = true
      debounceCounter = 0
      debug('headgear VFX: ' .. (showheadgear and 'ON' or 'OFF'))
  end
  HGvariantKeyWasDown = hgVarKeyDown

  local HGKeyDown = input.getBooleanActionValue('HGChange')
  if HGKeyDown and not headgearKeyWasDown then
      local availheadgear = getAvailableHeadgear()
      if #availheadgear > 0 then
          setShowheadgear(true)
          claimAHeadBone()
          local cur = getHeadgearIndex()
          if cur > #availheadgear then cur = #availheadgear end
          local nxt = cur % #availheadgear + 1
          setHeadgearIndex(nxt)
          counter = 1
          refresh = true
          debounceCounter = 15
          debug('headgear: ' .. availheadgear[nxt].stem .. ' (' .. nxt .. '/' .. #availheadgear .. ')')
      else
          debug('headgear: none available in inventory')
      end
  end
  headgearKeyWasDown = HGKeyDown

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
  showheadgear = FWheadgearState:get('showheadgear') or false
  counter = 3
  refresh = true
  lastSkins = nil
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
