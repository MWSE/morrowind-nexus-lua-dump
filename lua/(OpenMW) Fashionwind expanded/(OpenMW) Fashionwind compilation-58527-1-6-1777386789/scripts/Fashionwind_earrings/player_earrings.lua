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

local earringsSettings = storage.playerSection('Settings_tt_fashionwindEAR')

local BEAUT_SPELL_ID    = "fx_beauty"

local BUFF_SPELLS = {
    BEAUT_SPELL_ID,
}

local function applyEarringsBuffs(actor)
    if not earringsSettings:get('EARBUFFS') then return end
    for _, spellId in ipairs(BUFF_SPELLS) do
        Actor.spells(actor):add(spellId)
    end
end

local function removeEarringsBuffs(actor)
    for _, spellId in ipairs(BUFF_SPELLS) do
        Actor.spells(actor):remove(spellId)
    end
end

local cam     = camera.getMode()
local devMode = false

local VFX_ID   = 'visibleEarrings'
local vfxEarrings = { loop = true, useAmbientLight = false, vfxId = VFX_ID }

local EarringsListIndex = storage.playerSection('Settings_tt_earrings_cycle')
local EheadBoneOwner    = storage.playerSection('Settings_tt_earrings')
local settingsEAR        = storage.playerSection('Settings_tt_fashionwindEAR')
local FWearringsState   = storage.playerSection('Settings_tt_earrings_state')

local function getEarringsIndex()  return EarringsListIndex:get('cycleIndex') or 1 end
local function setEarringsIndex(n) EarringsListIndex:set('cycleIndex', n) end


local function claimEHeadBone() EheadBoneOwner:set('owner', 'earrings') end
local function EheadIsOurs()
  local owner = EheadBoneOwner:get('owner')
  return owner == nil or owner == 'earrings'
end

local earringsList = {
  'FemGDia', 'FemGEm', 'FemGRu', 'FemGSa', 'FemSDia', 'FemSEm', 'FemSRu', 'FemSSa', 'G01', 'G02', 'G03', 'G04', 'G05', 'G06', 'S01', 'S02', 'S03', 'S04', 'S05', 'S06', '_Earrings01', '_Earrings02', '_Earrings03a', '_Earrings03',
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

local function getAvailableEarrings()
  local stemMap   = buildStemMap()
  local available = {}
  for _, stem in ipairs(earringsList) do
      local skinsPath = stemMap[stem:lower()]
      if skinsPath then available[#available + 1] = { stem = stem, skins = skinsPath } end
  end
  return available
end

local showearrings          = FWearringsState:get('showearrings') or false
local earringsKeyWasDown    = false
local EARvariantKeyWasDown = false
local debounceCounter    = 0

local counter   = math.random(3, 20)
local refresh   = true
local newEquip  = false
local useHelper = false
local lastSkins = nil

local function setShowearrings(val)
  showearrings = val
  FWearringsState:set('showearrings', val)
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

  local availearrings  = getAvailableEarrings()
  local earIdx          = getEarringsIndex()
  if earIdx > #availearrings then earIdx = math.max(#availearrings, 1) end
  local activeSkins = availearrings[earIdx] and availearrings[earIdx].skins or nil

  local changed = (activeSkins ~= lastSkins) or reset
  if not changed then return end
  lastSkins = activeSkins

  debug('earrings: remove vfx')
  anim.removeVfx(self, VFX_ID)

  local vfxActive = showearrings and activeSkins and cam ~= MD.first and EheadIsOurs()

  if vfxActive then
      debug('earrings vfx: ' .. activeSkins)
      vfxEarrings.boneName = 'head'
      anim.addVfx(self, activeSkins, vfxEarrings)
      if earringsSettings:get('EARBUFFS') then
          applyEarringsBuffs(self)
      end
  else
      removeEarringsBuffs(self)
  end
end

local function onFrame(dt)
  if debounceCounter > 0 then
      debounceCounter = debounceCounter - 1
      return
  end

  local earVarKeyDown = input.getBooleanActionValue('EARShow')
  if earVarKeyDown and not EARvariantKeyWasDown then
      setShowearrings(not showearrings)
      if showearrings then claimEHeadBone() end
      counter = 1
      refresh = true
      debounceCounter = 0
      debug('earrings VFX: ' .. (showearrings and 'ON' or 'OFF'))
  end
  EARvariantKeyWasDown = earVarKeyDown

  local keyDown = input.getBooleanActionValue('EARChange')
  if keyDown and not earringsKeyWasDown then
      local availearrings = getAvailableEarrings()
      if #availearrings > 0 then
          setShowearrings(true)
          claimEHeadBone()
          local cur = getEarringsIndex()
          if cur > #availearrings then cur = #availearrings end
          local nxt = cur % #availearrings + 1
          setEarringsIndex(nxt)
          counter = 1
          refresh = true
          debounceCounter = 15
          debug('earrings: ' .. availearrings[nxt].stem .. ' (' .. nxt .. '/' .. #availearrings .. ')')
      else
          debug('earrings: none available in inventory')
      end
  end
  earringsKeyWasDown = keyDown

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
  showearrings = FWearringsState:get('showearrings') or false
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
