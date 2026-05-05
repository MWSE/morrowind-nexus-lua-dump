local self    = require('openmw.self')
local types   = require('openmw.types')
local anim    = require('openmw.animation')
local ui      = require('openmw.ui')
local async   = require('openmw.async')
local camera  = require('openmw.camera')
local storage = require('openmw.storage')
local input   = require('openmw.input')
local I       = require('openmw.interfaces')
local vfs     = require('openmw.vfs')
local core    = require('openmw.core')

local Actor = types.Actor
local MD    = { first = camera.MODE.FirstPerson, third = camera.MODE.ThirdPerson }

local СFROST_SPELL_ID = "fx_cloakshield"
local cam     = camera.getMode()
local devMode = false

local VFX_ID    = 'visibleCloak'
local vfxCloak  = { loop = true, useAmbientLight = false, vfxId = VFX_ID }

local cloakListIndex  = storage.playerSection('Settings_tt_fashionwind_cloak_cycle')
local spineBoneOwner  = storage.playerSection('Settings_tt_cloak')
local settingsSection = storage.playerSection('Settings_tt_visiblecloaks')

local function syncNpcCloakToGlobal()
    local raw     = settingsSection:get('CLOAKNPC')
    local enabled = (raw == nil) and true or (raw ~= false)
    core.sendGlobalEvent('cloakNpcSettingChanged', { enabled = enabled })
end

settingsSection:subscribe(async:callback(function(section, key)
    if key == 'CLOAKNPC' then
        syncNpcCloakToGlobal()
    end
end))

local function getCloakIndex()  return cloakListIndex:get('cycleIndex') or 1 end
local function setCloakIndex(n) cloakListIndex:set('cycleIndex', n) end

local function getShowCloak()   return cloakListIndex:get('showCloak') == true end
local function setShowCloak(v)  cloakListIndex:set('showCloak', v) end

local function getShowCloakKey()   return settingsSection:get('ShowCloak') end
local function getChangeCloakKey() return settingsSection:get('ChangeCloak') end
local function isCloakBuffEnabled() return settingsSection:get('CLOAKBUFF') == true end

local function claimSpineBone() spineBoneOwner:set('owner', 'cloak') end
local function spineIsOurs()
  local owner = spineBoneOwner:get('owner')
  return owner == nil or owner == 'cloak'
end

local cloakList = {
  'common_cape_03_b',
  'common_cape_04_b',
  'common_cape_05_b',
  'common_cape_black',
  'common_cape_blue',
  'common_cape_brown',
  'common_cape_brwn_blue',
  'common_cape_green',
  'common_cape_greensh',
  'common_cape_grey',
  'common_cape_morag',
  'common_cape_red',
  'common_cape_yellow',
  'expensive_cape_bg',
  'expensive_cape_RB',
  'expensive_cape_tel',
  'expensive_cape_tri',
  'exqs_cloak_01',
  'exqs_cloak_02',
  'extrav_cloak_01',
  'extrav_cloak_02',
  'extrav_cloak_03',
  'extrav_cloak_04',
  'extrav_cloak_05',
  'Dunmer_cloak',
  'Imperial_cloak',
  'Templar_cloak',
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

local function getAvailableCloaks()
  local stemMap   = buildStemMap()
  local available = {}
  for _, stem in ipairs(cloakList) do
      local skinsPath = stemMap[stem:lower()]
      if skinsPath then available[#available + 1] = { stem = stem, skins = skinsPath } end
  end
  return available
end

local showCloak          = getShowCloak()
local CloakKeyWasDown    = false
local CvariantKeyWasDown = false

local counter   = math.random(3, 20)
local refresh   = true
local newEquip  = false
local useHelper = false
local lastSkins = nil
local initDone  = false

local lastMotionSuffix = nil

local function updateCloakBuff()
  if showCloak and isCloakBuffEnabled() and #getAvailableCloaks() > 0 then
      Actor.spells(self):add(СFROST_SPELL_ID)
  else
      Actor.spells(self):remove(СFROST_SPELL_ID)
  end
end

local function setShowCloakState(val)
  showCloak = val
  cloakListIndex:set('showCloak', val)
  updateCloakBuff()
end

local function debug(m)
  if devMode then print(m); ui.showMessage(m) end
end

local lastPos    = nil
local frameSpeed = 0

local function updateFrameSpeed()
  local pos = self.position
  if not lastPos then
      lastPos    = pos
      frameSpeed = 0
      return
  end
  local dx = pos.x - lastPos.x
  local dy = pos.y - lastPos.y
  lastPos    = pos
  frameSpeed = math.sqrt(dx * dx + dy * dy)
end

local function getMotionSuffix()
  local walkSpeed = Actor.getWalkSpeed(self)
  local runSpeed  = Actor.getRunSpeed(self)

  if walkSpeed <= 0 or runSpeed <= 0 then
      if frameSpeed < 1 then return '_skins.nif'
      elseif frameSpeed < 3 then return '_skins1.nif'
      else return '_skins3.nif' end
  end

  local walkThresh = walkSpeed / 60
  local runThresh  = runSpeed  / 60

  if frameSpeed < walkThresh * 0.4 then
      return '_skins.nif'
  elseif frameSpeed < runThresh * 0.6 then
      return '_skins1.nif'
  else
      return '_skins3.nif'
  end
end

local function getAvailableSuffix(basePath, preferredSuffix)
  if vfs.fileExists(basePath .. preferredSuffix) then
      return preferredSuffix
  end
  if vfs.fileExists(basePath .. '_skins.nif') then
      return '_skins.nif'
  end
  return nil
end

local function getBasePath(skinsPath)
  return skinsPath:gsub('_skins%.nif$', '')
end

local function applyMotionVfx(skinsPath, suffix)
  local basePath        = getBasePath(skinsPath)
  local availableSuffix = getAvailableSuffix(basePath, suffix)
  if not availableSuffix then
      debug('No vfx file found for: ' .. basePath)
      return nil
  end
  local targetPath = basePath .. availableSuffix
  debug('cloak motion vfx: ' .. targetPath)
  anim.removeVfx(self, VFX_ID)
  vfxCloak.boneName = 'MEH'
  anim.addVfx(self, targetPath, vfxCloak)
  return availableSuffix
end

local function scanInv(reset)
  newEquip = false
  refresh  = false

  if showCloak then claimSpineBone() end

  local availCloaks = getAvailableCloaks()
  local cIdx        = getCloakIndex()
  if cIdx > #availCloaks then cIdx = math.max(#availCloaks, 1) end
  debug('Available Cloaks: ' .. #availCloaks .. ' | Current Index: ' .. cIdx)

  local activeSkins = availCloaks[cIdx] and availCloaks[cIdx].skins or nil
  if not activeSkins then
      debug('No active cloak found.')
      Actor.spells(self):remove(СFROST_SPELL_ID)
      lastSkins = nil
      return
  end

  updateCloakBuff()

  local changed = reset or (activeSkins ~= lastSkins)
  if not changed then return end

  anim.removeVfx(self, VFX_ID)
  lastMotionSuffix = nil

  if showCloak and cam ~= MD.first and spineIsOurs() then
      local suffix      = getMotionSuffix()
      local basePath    = getBasePath(activeSkins)
      local availSuffix = getAvailableSuffix(basePath, suffix) or '_skins.nif'
      local targetPath  = basePath .. availSuffix

      if vfs.fileExists(targetPath) then
          debug('Applying VFX: ' .. targetPath)
          vfxCloak.boneName = 'MEH'
          anim.addVfx(self, targetPath, vfxCloak)
          lastSkins        = activeSkins
          lastMotionSuffix = availSuffix
      else
          debug('VFX file missing: ' .. targetPath)
          lastSkins = nil
          refresh   = true
      end
  else
      lastSkins = activeSkins
  end
end

local function onInit()
    showCloak        = getShowCloak()
    lastSkins        = nil
    lastMotionSuffix = nil
    if showCloak then claimSpineBone() end
    counter  = 3
    refresh  = true
    initDone = true
    async:registerTimerCallback('syncNpc', function()
        syncNpcCloakToGlobal()
    end)
end

local function onFrame(dt)
  updateFrameSpeed()

  local showKey = getShowCloakKey()
  local keyDown = (type(showKey) == 'number') and input.isKeyPressed(showKey) or false
  if keyDown and not CloakKeyWasDown then
      setShowCloakState(not showCloak)
      setShowCloak(showCloak)
      if showCloak then claimSpineBone() end
      counter          = 1
      refresh          = true
      lastMotionSuffix = nil
      debug('Cloak VFX toggled: ' .. (showCloak and 'ON' or 'OFF'))
  end
  CloakKeyWasDown = keyDown

  local changeKey = getChangeCloakKey()
  local cVarKeyDown = (type(changeKey) == 'number') and input.isKeyPressed(changeKey) or false
  if cVarKeyDown and not CvariantKeyWasDown then
      local availCloaks = getAvailableCloaks()
      if #availCloaks > 0 then
          showCloak = true
          setShowCloak(showCloak)
          claimSpineBone()
          local cur = getCloakIndex()
          local nxt = cur % #availCloaks + 1
          setCloakIndex(nxt)
          counter          = 1
          refresh          = true
          lastMotionSuffix = nil
          debug('Cloak changed: ' .. availCloaks[nxt].stem)
      else
          debug('No cloaks in inventory.')
      end
  end
  CvariantKeyWasDown = cVarKeyDown

  if newEquip or refresh then
      scanInv(true)
  end

  counter = counter - 1

  if showCloak and lastSkins and cam ~= MD.first and spineIsOurs() and initDone then
      local suffix = getMotionSuffix()
      if suffix ~= lastMotionSuffix then
          debug('Motion suffix changed: ' .. tostring(lastMotionSuffix) .. ' -> ' .. suffix)
          local appliedSuffix = applyMotionVfx(lastSkins, suffix)
          lastMotionSuffix = appliedSuffix or suffix
      end
  end

  if counter <= 0 then
      counter = 20
      if refresh or not useHelper or not initDone then
          scanInv(true)
      end
  end
end

local function onUpdate(dt)
  if dt == 0 then return end
  if cam == camera.getMode() then return end
  local mode, fp = camera.getMode(), MD.first
  if mode == fp or cam == fp then
      cam     = mode
      counter = 3
      refresh = true
  end
  cam = mode
end

return {
  engineHandlers = {
      onUpdate = onUpdate,
      onFrame  = onFrame,
      onInit = function()
          onInit()
          async:newSimulationTimer(0, async:callback(function()
              syncNpcCloakToGlobal()
          end))
      end,
  },
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
          if not useHelper then
              useHelper = true
              I.luaHelper.eventRegister('equipped',   function() newEquip = true end)
              I.luaHelper.eventRegister('unequipped', function() newEquip = true end)
          end
      end,
      vfxRemoveAll = function()
          counter          = math.random(18, 24)
          refresh          = true
          lastMotionSuffix = nil
      end,
  },
}