-- scripts/ohs_toggle/player.lua (OpenMW 0.49/0.50)
-- Player-local controller for the OHS toggle:
-- • Robust equip pipeline with durability/enchant-charge preservation
-- • Longsword Skill Bridge (skill level sync) + XP reroute to origin skill
-- • (1H) spear thrust-only (our spear stand-in only)
-- • Safe with non-weapon right-hand items (lockpicks/probes)
-- • SAVE-SAFE v3: we never scrub on save; we store LB_delta in savedData and always subtract it onLoad.

local self    = require('openmw.self')
local types   = require('openmw.types')
local core    = require('openmw.core')
local input   = require('openmw.input')
local async   = require('openmw.async')
local ui      = require('openmw.ui')
local store   = require('openmw.storage')
local I       = require('openmw.interfaces')

local EQUIP   = types.Actor.EQUIPMENT_SLOT
local STANCE  = types.Actor.STANCE
local Item    = types.Item
local Weapon  = types.Weapon
local WTYPE   = types.Weapon.TYPE
local NPC     = types.NPC

-- Settings group (must match menu.lua)
local SETTINGS_GROUP = 'SettingsOHS_Toggle'
local settings       = store.globalSection(SETTINGS_GROUP)

-- Debug helpers
local function dbgEnabled() return settings and settings:get('DebugLog') == true end
local function dbg(...) if dbgEnabled() then print('[OHS][PLAYER]', ...) end end
local _dbgLast
local function pollDebugFlip()
  local cur = dbgEnabled()
  if _dbgLast == nil then _dbgLast = cur; return end
  if cur ~= _dbgLast then
    print('[OHS][PLAYER]', 'Debug logging ' .. (cur and 'ENABLED' or 'DISABLED'))
    _dbgLast = cur
  end
end

-- Session runtime (not saved with the game; avoids cross-save bleed)
local runtime = store.playerSection('OHS_Toggle_Runtime')
runtime:setLifeTime(store.LIFE_TIME.Temporary) -- cleared on context reset / save load
local function getLastApplied() return runtime:get('LB_lastApplied') or 0 end
local function setLastApplied(v) runtime:set('LB_lastApplied', v) end

-- Trigger key (must match your settings UI)
local TOGGLE_TRIGGER = 'OHS_ToggleSpear'

-- UI deferral (so we don't equip during barter/container/dialogue)
local uiBlocked = false
local function forwardUiModeChanged(data)
  if not data then return end
  if data.newMode == 'Barter' or data.newMode == 'Container' or data.newMode == 'Dialogue' then
    uiBlocked = true
  end
  if data.oldMode == 'Dialogue' or data.oldMode == 'Container' then
    uiBlocked = false
  end
end

-- ---------- Safe right-hand weapon record ----------
local function getRightHandWeaponRecord()
  local eq = types.Actor.equipment(self.object)
  local rh = eq and eq[EQUIP.CarriedRight] or nil
  if not (rh and rh:isValid()) then return nil end
  if not types.Weapon.objectIsInstance(rh) then return nil end -- guards lockpicks/probes/etc.
  return types.Weapon.record(rh)
end

-- ---------- Equip pipeline ----------
local pendingEquip      -- { newObj, oldObj, note }
local pendingCleanup    -- { oldObj, expectRecId, tries }

local function preserveDurabilityAndCharge(oldObj, newObj)
  if not (oldObj and oldObj:isValid()) then return end
  if not (newObj and newObj:isValid()) then return end
  local oldRec, newRec = Weapon.record(oldObj), Weapon.record(newObj)
  if not (oldRec and newRec) then return end
  local oldData, newData = Item.itemData(oldObj), Item.itemData(newObj)
  if not (oldData and newData) then return end

  -- % condition carryover
  local oldMax, newMax = oldRec.health or 0, newRec.health or 0
  if oldMax > 0 and newMax > 0 then
    local pct  = (oldData.condition or oldMax) / oldMax
    local cond = math.floor(pct * newMax + 0.5)
    if cond < 1 and (oldData.condition or 0) > 0 then cond = 1 end
    newData.condition = cond
  end

  -- enchantment charge carryover
  if oldRec.enchant and newRec.enchant then
    local oldEnc = core.magic.enchantments.records[oldRec.enchant]
    local newEnc = core.magic.enchantments.records[newRec.enchant]
    local oldMaxC = (oldEnc and oldEnc.charge) or 0
    local newMaxC = (newEnc and newEnc.charge) or 0
    if newMaxC > 0 then
      local oldCharge = oldData.enchantmentCharge
      local src = (oldCharge == nil) and oldMaxC or oldCharge
      if src > newMaxC then src = newMaxC end
      if src < 0 then src = 0 end
      newData.enchantmentCharge = math.floor(src + 0.5)
    end
  end
end

local function rightIs(recordId)
  local rec = getRightHandWeaponRecord()
  return rec and rec.id == recordId
end

local function finishCleanupIfEquipped()
  if not pendingCleanup then return end
  if rightIs(pendingCleanup.expectRecId) then
    if pendingCleanup.oldObj and pendingCleanup.oldObj:isValid() then
      core.sendGlobalEvent('OHS_RemoveObject', { object = pendingCleanup.oldObj })
    end
    pendingCleanup = nil
    core.sendGlobalEvent('OHS_SwapComplete', { actor = self.object })
    return
  end
  pendingCleanup.tries = pendingCleanup.tries - 1
  if pendingCleanup.tries <= 0 then
    dbg('Equip verify timeout; leaving old instance to be safe')
    pendingCleanup = nil
    core.sendGlobalEvent('OHS_SwapComplete', { actor = self.object })
  end
end

local function tryEquip()
  if not pendingEquip then
    finishCleanupIfEquipped()
    return
  end
  if uiBlocked then return end

  local newObj = pendingEquip.newObj
  local oldObj = pendingEquip.oldObj
  local note   = pendingEquip.note
  pendingEquip = nil

  if not (newObj and newObj:isValid()) then
    dbg('Equip aborted: invalid new object')
    core.sendGlobalEvent('OHS_SwapComplete', { actor = self.object })
    return
  end
  local newRec = Weapon.record(newObj)
  if not newRec then
    dbg('Equip aborted: new object has no weapon record')
    core.sendGlobalEvent('OHS_SwapComplete', { actor = self.object })
    return
  end

  pcall(preserveDurabilityAndCharge, oldObj, newObj)

  local current = types.Actor.equipment(self.object)
  current[EQUIP.CarriedRight] = newObj

  local okSet, errSet = pcall(function()
    -- IMPORTANT: pass the actor object, not the module
    types.Actor.setEquipment(self.object, current)
  end)

  if okSet and rightIs(newRec.id) then
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

  pendingCleanup = { oldObj = (oldObj ~= newObj) and oldObj or nil, expectRecId = newRec.id, tries = 20 }
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
local handlerHooked = false
local function ensureTriggerRegistered()
  if input.triggers and input.triggers[TOGGLE_TRIGGER] then return end
  local ok, err = pcall(function()
    input.registerTrigger {
      key         = TOGGLE_TRIGGER,
      l10n        = 'ohs_toggle',
      name        = 'toggle_binding_name',
      description = 'toggle_binding_desc',
    }
  end)
  if not ok then dbg('registerTrigger skipped:', tostring(err))
  else dbg('Registered trigger', TOGGLE_TRIGGER) end
end

local function hookTrigger()
  if handlerHooked then return end
  input.registerTriggerHandler(TOGGLE_TRIGGER, async:callback(function()
    if dbgEnabled() then print('[OHS][PLAYER]', 'Trigger fired:', TOGGLE_TRIGGER) end
    core.sendGlobalEvent('OHS_ToggleNow', { actor = self.object })
  end))
  handlerHooked = true
  dbg('Hooked trigger handler for', TOGGLE_TRIGGER)
end

-- ---------- Stance watcher (for sheath fix) ----------
local lastStance = STANCE.Nothing
local function pollStance()
  local now = types.Actor.getStance and types.Actor.getStance(self.object) or types.Actor.stance(self.object)
  if now ~= lastStance then
    core.sendGlobalEvent('OHS_StanceChanged', { actor = self.object, old = lastStance, new = now })
    lastStance = now
  end
end

-- ---------- Longsword Skill Bridge + XP reroute ----------
local SUFFIX_1H, SUFFIX_2H = " (1H)", " (2H)"
local function endswith(s, suf) return s and suf and s:sub(-#suf) == suf end

-- caches to avoid per-frame scans and redundant writes
local _cache = {
  nameTypeIndex = nil,            -- key = "<name>|<type>", value = record (first seen)
  originByRecId = {},             -- rec.id -> 'shortblade'|'bluntweapon'|'spear'|nil
  lastRHRecId   = nil,            -- last right-hand record id
}

local function buildNameTypeIndexOnce()
  if _cache.nameTypeIndex then return end
  _cache.nameTypeIndex = {}
  for _, rec in ipairs(Weapon.records) do
    local key = tostring(rec.name or '') .. '|' .. tostring(rec.type)
    if _cache.nameTypeIndex[key] == nil then
      _cache.nameTypeIndex[key] = rec
    end
  end
end

local function findBaseByNameAndType(baseName, typeConst)
  buildNameTypeIndexOnce()
  return _cache.nameTypeIndex[tostring(baseName or '') .. '|' .. tostring(typeConst)]
end

-- Identify our stand-ins:
--  (2H) longsword from blunt(1H) or shortblade(1H)
--  (1H) longsword from spear(2H)
local function originSkillForLongswordRecord(rec)
  if not rec then return nil end
  -- memoize by record id
  local cached = _cache.originByRecId[rec.id]
  if cached ~= nil then return cached end

  local origin = nil
  if rec.type == WTYPE.LongBladeTwoHand and endswith(rec.name, SUFFIX_2H) then
    local baseName = rec.name:sub(1, #rec.name - #SUFFIX_2H)
    if     findBaseByNameAndType(baseName, WTYPE.BluntOneHand)         then origin = 'bluntweapon'
    elseif findBaseByNameAndType(baseName, WTYPE.ShortBladeOneHand)    then origin = 'shortblade'
    end
  elseif rec.type == WTYPE.LongBladeOneHand and endswith(rec.name, SUFFIX_1H) then
    local baseName = rec.name:sub(1, #rec.name - #SUFFIX_1H)
    if findBaseByNameAndType(baseName, WTYPE.SpearTwoWide)              then origin = 'spear' end
  end

  _cache.originByRecId[rec.id] = origin
  return origin
end

-- NEW: precisely recognize only *non-LB* stand-ins (used below to decide whether to consume LB XP)
local function isNonLongbladeStandIn(rec)
  if not rec then return false end
  if rec.type == WTYPE.LongBladeOneHand and endswith(rec.name, SUFFIX_1H) then
    local baseName = rec.name:sub(1, #rec.name - #SUFFIX_1H)
    return findBaseByNameAndType(baseName, WTYPE.SpearTwoWide) ~= nil
  elseif rec.type == WTYPE.LongBladeTwoHand and endswith(rec.name, SUFFIX_2H) then
    local baseName = rec.name:sub(1, #rec.name - #SUFFIX_2H)
    return (findBaseByNameAndType(baseName, WTYPE.BluntOneHand) ~= nil)
        or (findBaseByNameAndType(baseName, WTYPE.ShortBladeOneHand) ~= nil)
  end
  return false
end

local _bridge = { active = false, origin = nil, lastApplied = 0 }

local function applySkillBridge(originSkillId)
  local lb         = NPC.stats.skills.longblade(self)
  local originStat = NPC.stats.skills[originSkillId](self)

  local previousApplied = getLastApplied()
  _bridge.lastApplied = previousApplied

  local baseline    = lb.modifier - (previousApplied or 0)
  local target      = originStat.modified
  local have        = (lb.base + baseline - (lb.damage or 0))
  local newApplied  = target - have

  if math.abs((newApplied or 0) - (previousApplied or 0)) < 0.0001 and _bridge.active and _bridge.origin == originSkillId then
    return
  end

  lb.modifier = baseline + newApplied
  _bridge.lastApplied = newApplied
  setLastApplied(newApplied)

  _bridge.active = true
  _bridge.origin = originSkillId
end

local function clearSkillBridge()
  local last = _bridge.lastApplied or getLastApplied() or 0
  if math.abs(last) > 0.0001 then
    local lb = NPC.stats.skills.longblade(self)
    lb.modifier = lb.modifier - last
    setLastApplied(0)
  end
  _bridge.lastApplied = 0
  _bridge.active = false
  _bridge.origin = nil
end

-- Only react when the right-hand weapon actually changes
local function pollSkillBridge()
  local rec = getRightHandWeaponRecord()
  local recId = rec and rec.id or nil

  if recId == _cache.lastRHRecId then
    return
  end

  _cache.lastRHRecId = recId

  local origin = rec and originSkillForLongswordRecord(rec) or nil
  if origin then
    applySkillBridge(origin)
  else
    clearSkillBridge()
  end
end

-- (1H) Spear thrust-only (only for our stand-in)
local function isOneHandSpearStandIn(rec)
  if not rec then return false end
  if rec.type ~= WTYPE.LongBladeOneHand then return false end
  if not endswith(rec.name, SUFFIX_1H) then return false end
  local baseName = rec.name:sub(1, #rec.name - #SUFFIX_1H)
  return findBaseByNameAndType(baseName, WTYPE.SpearTwoWide) ~= nil
end

local function enforceThrustForSpears()
  if not settings or not settings:get('AlwaysThrustSpears') then return end
  local stance = types.Actor.getStance and types.Actor.getStance(self.object) or types.Actor.stance(self.object)
  if stance ~= STANCE.Weapon then return end
  local rec = getRightHandWeaponRecord()
  if not isOneHandSpearStandIn(rec) then return end
  if self.controls.use ~= self.ATTACK_TYPE.NoAttack then
    self.controls.use = self.ATTACK_TYPE.Thrust
  end
end

-- XP reroute: neutralize Long Blade XP ONLY for non-LB stand-ins, and re-award to origin skill
local _rerouteGuard = false
I.SkillProgression.addSkillUsedHandler(function(skillid, params)
  if _rerouteGuard then return end
  if skillid ~= 'longblade' then return end
  if not params then return end

  local rec = getRightHandWeaponRecord()
  if not rec then return end

  -- Identify the base skill for our Longsword stand-ins:
  local origin = originSkillForLongswordRecord(rec)

  -- If we have a recognized non-LB origin, reroute LB XP to that origin and CONSUME the event.
  if origin then
    local useType = params.useType
    local gain    = params.skillGain
    local scale   = params.scale

    -- Re-award to the origin skill under a guard
    _rerouteGuard = true
    I.SkillProgression.skillUsed(origin, {
      useType   = useType or I.SkillProgression.SKILL_USE_TYPES.Weapon_SuccessfulHit,
      skillGain = gain,  -- may be nil; engine computes from useType/scale
      scale     = scale,
    })
    _rerouteGuard = false

    -- After origin changes, re-apply bridge once (cheap)
    if origin == originSkillForLongswordRecord(rec) then
      applySkillBridge(origin)
    end

    -- Consume LB event so no default/other handlers can add LB XP.
    return false
  end

  -- Otherwise, do NOT consume if this is a Long Blade <-> Long Blade toggle.
  -- Only consume as a safety net when we can prove it's our *non-LB* stand-in.
  if isNonLongbladeStandIn(rec) then
    return false
  end
  -- Fallthrough: let the engine/default handler award Long Blade XP.
end)

-- ---------- Engine / Events ----------
return {
  engineHandlers = {
    onInit = function()
      ensureTriggerRegistered()
      hookTrigger()
      buildNameTypeIndexOnce() -- prebuild to avoid a first-frame hitch later
    end,

    onLoad = function(saved)
      ensureTriggerRegistered()
      hookTrigger()

      -- Subtract our previous bridge on load (save-safe)
      local delta = (type(saved) == 'table' and saved.LB_delta) or 0
      if math.abs(delta or 0) > 0.0001 then
        local lb = NPC.stats.skills.longblade(self)
        lb.modifier = lb.modifier - delta
        if dbgEnabled() then print('[OHS][PLAYER]', 'onLoad: subtracted LB_delta =', delta) end
      else
        if dbgEnabled() then print('[OHS][PLAYER]', 'onLoad: LB_delta absent or 0 (no change)') end
      end

      -- Reset session state; poller will re-derive if a stand-in is equipped.
      setLastApplied(0)
      _bridge.lastApplied = 0
      _bridge.active = false
      _bridge.origin = nil
      _cache.lastRHRecId = nil
    end,

    onSave = function()
      local delta = getLastApplied() or 0
      if dbgEnabled() then print('[OHS][PLAYER]', 'onSave: storing LB_delta =', delta) end
      return { LB_delta = delta }
    end,

    onUpdate = function(_dt)
      pollDebugFlip()
      pollStance()
      tryEquip()
      pollSkillBridge()
      enforceThrustForSpears()
    end,
  },

  eventHandlers = {
    UiModeChanged   = forwardUiModeChanged,
    OHS_LocalEquip  = queueEquip,
    OHS_ShowMessage = function(data)
      local text = (type(data) == 'string') and data or (data and data.text) or nil
      if text and #text > 0 then ui.showMessage(text) end
    end,
  },
}
