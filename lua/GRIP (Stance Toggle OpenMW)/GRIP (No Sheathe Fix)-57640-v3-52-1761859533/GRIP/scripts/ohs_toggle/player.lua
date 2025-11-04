-- scripts/ohs_toggle/player.lua (OpenMW 0.49/0.50)
local core   = require('openmw.core')
local types  = require('openmw.types')
local input  = require('openmw.input')
local async  = require('openmw.async')
local ui     = require('openmw.ui')
local self   = require('openmw.self')
local store  = require('openmw.storage')
local I      = require('openmw.interfaces')

local EQUIP  = types.Actor.EQUIPMENT_SLOT
local WTYPE  = types.Weapon.TYPE
local STANCE = types.Actor.STANCE

-- Settings
local SETTINGS_GROUP = 'SettingsOHS_Toggle'
local settings       = store.globalSection(SETTINGS_GROUP)

local function dbgEnabled() return settings and settings:get('DebugLog') == true end
local function dbg(...) if dbgEnabled() then print('[OHS][PLAYER]', ...) end end

-- ---------- Equip pipeline ----------
local pendingEquip    = nil
local pendingCleanup  = nil

local function rightIs(recId)
  local eq = types.Actor.getEquipment(self.object)
  local rh = eq and eq[EQUIP.CarriedRight] or nil
  if not (rh and rh:isValid()) then return false end
  local rec = types.Weapon.record(rh)
  return rec and rec.id == recId
end

local function performEquip(newObj, oldObj, note)
  if not (newObj and newObj:isValid()) then return end
  local newRec = types.Weapon.record(newObj)
  local current = types.Actor.equipment(self.object)
  current[EQUIP.CarriedRight] = newObj

  local okSet, errSet = pcall(function()
    types.Actor.setEquipment(self.object, current)
  end)

  if okSet and newRec and rightIs(newRec.id) then
    if note and #note > 0 then ui.showMessage(note) end
    if oldObj and oldObj:isValid() and (oldObj ~= newObj) then
      core.sendGlobalEvent('OHS_RemoveObject', { object = oldObj })
    end
    core.sendGlobalEvent('OHS_SwapComplete', { actor = self.object })
    return
  end

  dbg('setEquipment did not stick (' .. tostring(errSet) .. '); falling back to UseItem')
  core.sendGlobalEvent('UseItem', { object = newObj, actor = self.object, force = true })
  if note and #note > 0 then ui.showMessage(note) end

  pendingCleanup = { oldObj = (oldObj ~= newObj) and oldObj or nil, expectRecId = newRec and newRec.id or nil, tries = 20 }
end

local function queueEquip(data)
  local obj = data and data.object
  if obj and obj:isValid() then
    pendingEquip = { newObj = obj, oldObj = data.old, note = data.note }
    dbg('Queued OHS_LocalEquip for', obj.recordId)
  else
    dbg('Ignored OHS_LocalEquip (invalid object)')
    core.sendGlobalEvent('OHS_SwapComplete', { actor = self.object })
  end
end

-- ---------- Trigger ----------
local TRIG_PRIMARY = 'ohs_toggle'
local TRIG_LEGACY  = 'OHS_ToggleSpear' -- backward compatibility with old saves
local handlersHooked = false

local function ensureTriggersRegistered()
  local function reg(key)
    if input.triggers and input.triggers[key] then return end
    pcall(function()
      input.registerTrigger {
        key         = key,
        l10n        = 'ohs_toggle',
        name        = 'toggle_binding_name',
        description = 'toggle_binding_desc',
      }
    end)
  end
  reg(TRIG_PRIMARY)
  reg(TRIG_LEGACY)
end

local function hookHandlers()
  if handlersHooked then return end
  local cb = async:callback(function()
    if dbgEnabled() then print('[OHS][PLAYER]', 'Trigger fired') end
    core.sendGlobalEvent('OHS_ToggleNow', { actor = self.object })
  end)
  -- Hook both the primary and the legacy key
  input.registerTriggerHandler(TRIG_PRIMARY, cb)
  input.registerTriggerHandler(TRIG_LEGACY,  cb)
  handlersHooked = true
  dbg('Hooked trigger handlers for', TRIG_PRIMARY, 'and legacy', TRIG_LEGACY)
end

-- ---------- Longsword Skill Bridge + basic XP reroute ----------
local SUFFIX_1H, SUFFIX_2H = " (1H)", " (2H)"
local function endswith(s, suf) return s and suf and s:sub(-#suf) == suf end

-- Cache of base name+type -> record (used to detect origin skill of our stand-ins)
local _nameTypeIndex = nil
local function buildNameTypeIndexOnce()
  if _nameTypeIndex then return end
  _nameTypeIndex = {}
  for _, rec in ipairs(types.Weapon.records) do
    local key = tostring(rec.name or '') .. '|' .. tostring(rec.type)
    if _nameTypeIndex[key] == nil then
      _nameTypeIndex[key] = rec
    end
  end
end
local function findBaseByNameAndType(baseName, typeConst)
  buildNameTypeIndexOnce()
  return _nameTypeIndex[tostring(baseName or '') .. '|' .. tostring(typeConst)]
end

-- If currently wielding our stand-ins, return the *origin* skill that should receive XP
local function originSkillForLongswordRecord(rec)
  if not rec then return nil end
  if rec.type == WTYPE.LongBladeTwoHand and endswith(rec.name, SUFFIX_2H) then
    local baseName = rec.name:sub(1, #rec.name - #SUFFIX_2H)
    if     findBaseByNameAndType(baseName, WTYPE.BluntOneHand)         then return 'bluntweapon'
    elseif findBaseByNameAndType(baseName, WTYPE.ShortBladeOneHand)    then return 'shortblade'
    end
  elseif rec.type == WTYPE.LongBladeOneHand and endswith(rec.name, SUFFIX_1H) then
    local baseName = rec.name:sub(1, #rec.name - #SUFFIX_1H)
    if findBaseByNameAndType(baseName, WTYPE.SpearTwoWide) then return 'spear' end
  end
  return nil
end

-- Register the bridge with the 0.49/0.50 SkillProgression interface
-- When longblade gets XP from a hit while our stand-ins are equipped,
-- zero-out longblade's gain and give the same gain to the origin skill.
I.SkillProgression.addSkillUsedHandler(function(skillid, params)
  if skillid ~= 'longblade' then return end

  -- What are we actually holding?
  local rec = nil
  local eq = types.Actor.getEquipment(self.object)
  local rh = eq and eq[EQUIP.CarriedRight] or nil
  if rh and rh:isValid() and types.Weapon.objectIsInstance(rh) then
    rec = types.Weapon.record(rh)
  end

  local origin = originSkillForLongswordRecord(rec)
  if not origin then return end

  local gain    = params.skillGain or 0
  local useType = params.useType or I.SkillProgression.SKILL_USE_TYPES.Weapon_SuccessfulHit

  -- Cancel longblade's gain for this hit and forward it to the origin skill.
  params.skillGain = 0
  I.SkillProgression.skillUsed(origin, { skillGain = gain, useType = useType })
end)

-- ---------- Engine ----------
local function doTick()
  ensureTriggersRegistered()
  hookHandlers()

  if pendingEquip then
    local e = pendingEquip
    pendingEquip = nil
    performEquip(e.newObj, e.oldObj, e.note)
  end

  if pendingCleanup then
    local ok = false
    if pendingCleanup.expectRecId then
      ok = rightIs(pendingCleanup.expectRecId)
    end
    if ok then
      if pendingCleanup.oldObj and pendingCleanup.oldObj:isValid() then
        core.sendGlobalEvent('OHS_RemoveObject', { object = pendingCleanup.oldObj })
      end
      core.sendGlobalEvent('OHS_SwapComplete', { actor = self.object })
      pendingCleanup = nil
    else
      pendingCleanup.tries = (pendingCleanup.tries or 0) - 1
      if pendingCleanup.tries <= 0 then
        core.sendGlobalEvent('OHS_SwapComplete', { actor = self.object })
        pendingCleanup = nil
      end
    end
  end
end

return {
  engineHandlers = {
    onUpdate = function(_) doTick() end,
  },
  eventHandlers = {
    OHS_LocalEquip = function(data) queueEquip(data) end,
    OHS_ShowMessage = function(data)
      local msg = data and data.text
      if msg and #msg > 0 then ui.showMessage(msg) end
    end,
    -- OHS_StanceChanged no longer used (back-sheath swap disabled)
  },
}
