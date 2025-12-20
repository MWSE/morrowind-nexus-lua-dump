-- scripts/ohs_toggle/player.lua (OpenMW 0.49)
-- Player-local controller for the OHS toggle:
-- • Robust equip pipeline with durability/enchant-charge preservation
-- • Longsword Skill Bridge (skill level sync) + XP reroute to origin skill
-- • (1H) spear thrust-only (our spear stand-in only)
-- • Safe with non-weapon right-hand items (lockpicks/probes)
-- • SAVE-SAFE v3: we never scrub on save; we store LB_delta in savedData and always subtract it onLoad.

local self                      = require('openmw.self')
local types                     = require('openmw.types')
local core                      = require('openmw.core')
local input                     = require('openmw.input')
local async                     = require('openmw.async')
local ui                        = require('openmw.ui')
local store                     = require('openmw.storage')
local I                         = require('openmw.interfaces')

local EQUIP                     = types.Actor.EQUIPMENT_SLOT
local STANCE                    = types.Actor.STANCE
local WTYPE                     = types.Weapon.TYPE
local NPC                       = types.NPC
local alreadySwapping           = false

local SETTINGS_GROUP            = 'SettingsOHS_Toggle'
local settings                  = store.playerSection(SETTINGS_GROUP)
local DebugEnable, AlwaysThrust = settings:get('DebugLog'), settings:get('AlwaysThrustSpears')
settings:subscribe(
  async:callback(
    function(_, key)
      local value = settings:get(key)

      if key == 'DebugLog' then
        DebugEnable = value
      elseif key == 'AlwaysThrustSpears' then
        AlwaysThrust = value
      end
    end
  )
)

local function dbg(...)
  if not DebugEnable then return end
  print('[OHS][PLAYER]', ...)
end

local lastApplied = 0
local function getLastApplied() return lastApplied end
local function setLastApplied(v) lastApplied = v end

local Records = store.globalSection('GRIPRecords')
local OldToNewRecords, NewToOldRecords, NormalToSheath, SheathToNormal = {}, {}, {}, {}
Records:subscribe(
  async:callback(
    function(_, key)
      local value = Records:get(key)

      if key == 'OldToNewRecords' then
        OldToNewRecords = value
      elseif key == 'NewToOldRecords' then
        NewToOldRecords = value
      elseif key == 'NormalToSheath' then
        NormalToSheath = value
      elseif key == 'SheathToNormal' then
        SheathToNormal = value
      end
    end
  )
)

-- Trigger key (must match menu.lua registration)
local TOGGLE_TRIGGER = 'OHS_ToggleSpear'

-- UI deferral (so we don't equip during barter/container/dialogue)
local uiBlocked = false
local blockingModes = {
  Barter = true,
  Container = true,
  Dialogue = true,
}

local function UiModeChanged(data)
  if blockingModes[data.newMode] then
    uiBlocked = true
  elseif blockingModes[data.oldMode] then
    uiBlocked = false
  end
end

-- ---------- Safe right-hand weapon record ----------
local function getRightHandWeaponRecord()
  local rh = types.Actor.equipment(self.object, EQUIP.CarriedRight)
  if not rh then return end

  return types.Weapon.records[rh.recordId]
end

local featherEffect = core.magic.EFFECT_TYPE.Feather
local activeEffects = self.type.activeEffects(self)
local function equipWeapon(data)
  assert(data and data.object and data.object.__type.name == 'MWLua::LObject')

  local object = data.object
  assert(
    types.Weapon.objectIsInstance(object),
    'equipWeapon can only equip weapons!!!!!'
  )

  local equipment = self.type.getEquipment(self)
  equipment[self.type.EQUIPMENT_SLOT.CarriedRight] = object
  self.type.setEquipment(self, equipment)

  if data.negateFeather then
    local weight = object.type.records[object.recordId].weight

    activeEffects:modify(-weight, featherEffect)
  end

  core.sendGlobalEvent('OHS_RemoveObject', data.old)

  if alreadySwapping then alreadySwapping = false end
end

input.registerActionHandler(TOGGLE_TRIGGER,
  async:callback(
    function(state)
      if state or alreadySwapping or uiBlocked or core.isWorldPaused() then return end
      alreadySwapping = true

      dbg('[OHS][PLAYER]', 'Trigger fired:', TOGGLE_TRIGGER)

      local weapon = self.type.getEquipment(self, self.type.EQUIPMENT_SLOT.CarriedRight)
      if not weapon then return ui.showMessage('Equip a weapon to use the stance toggle') end

      core.sendGlobalEvent('OHS_ToggleNow',
        {
          actor = self.object,
          weapon = weapon
        }
      )
    end
  )
)

local stanceFunction = types.Actor.getStance and types.Actor.getStance or types.Actor.stance
-- ---------- Stance watcher (for sheath fix) ----------
local lastStance = STANCE.Nothing
local function pollStance()
  local weapon = self.type.getEquipment(self, self.type.EQUIPMENT_SLOT.CarriedRight)
  if not weapon then return end

  local now = stanceFunction(self)

  if now == lastStance then return end

  core.sendGlobalEvent(
    'OHS_StanceChanged',
    {
      actor = self.object,
      old = lastStance,
      new = now,
      weapon = weapon,
    }
  )

  lastStance = now
end

local function originSkillForLongswordRecord(rec)
  assert(rec)

  local originalId = NewToOldRecords[rec.id]
  if not rec or not originalId then return end
  local originalRecord = types.Weapon.records[originalId]

  if rec.type == WTYPE.LongBladeTwoHand then
    if originalRecord.type == WTYPE.BluntOneHand then
      return 'bluntweapon'
    elseif originalRecord.type == WTYPE.ShortBladeOneHand then
      return 'shortblade'
    end
  elseif rec.type == WTYPE.LongBladeOneHand and originalRecord.type == WTYPE.SpearTwoWide then
    return 'spear'
  end
end

local _bridge = { active = false, origin = nil, lastApplied = 0 }

local longBlade = self.type.stats.skills.longblade(self)
local skills = {}
local function applySkillBridge(originSkillId)
  local originStat = skills[originSkillId] or NPC.stats.skills[originSkillId](self)

  if not skills[originSkillId] then
    skills[originSkillId] = originStat
  end

  _bridge.lastApplied = getLastApplied()

  local baseline      = longBlade.modifier - (_bridge.lastApplied or 0)
  local target        = originStat.modified
  local have          = (longBlade.base + baseline - (longBlade.damage or 0))
  local newApplied    = target - have

  longBlade.modifier  = baseline + newApplied
  _bridge.lastApplied = newApplied
  setLastApplied(newApplied)

  _bridge.active = true
  _bridge.origin = originSkillId
end

local function clearSkillBridge()
  local last = _bridge.lastApplied or getLastApplied() or 0
  if math.abs(last) > 0.0001 then
    longBlade.modifier = longBlade.modifier - last
    setLastApplied(0)
  end
  _bridge.lastApplied = 0
  _bridge.active = false
  _bridge.origin = nil
end

-- Always apply when our stand-in is in hand; otherwise clear.
local function pollSkillBridge()
  local rec = getRightHandWeaponRecord()
  local origin = rec and originSkillForLongswordRecord(rec) or nil
  if origin then
    applySkillBridge(origin)
  else
    clearSkillBridge()
  end
end

-- (1H) Spear thrust-only (only for our stand-in)
local function isOneHandSpearStandIn(rec)
  assert(rec)
  local originalId = NewToOldRecords[rec.id]

  return rec.type == WTYPE.LongBladeOneHand
      and originalId
      and types.Weapon.records[originalId].type == WTYPE.SpearTwoWide
end

local function enforceThrustForSpears()
  if not AlwaysThrust then return end

  if stanceFunction(self) ~= STANCE.Weapon then return end

  local rec = getRightHandWeaponRecord()
  if not isOneHandSpearStandIn(rec) then return end

  if self.controls.use ~= self.ATTACK_TYPE.NoAttack then
    self.controls.use = self.ATTACK_TYPE.Thrust
  end
end

-- XP reroute: neutralize Long Blade XP and re-award to origin skill
local _rerouteGuard = false
I.SkillProgression.addSkillUsedHandler(function(skillid, params)
  if _rerouteGuard or skillid ~= 'longblade' or not params then return end

  local rec = getRightHandWeaponRecord()
  if not rec then return end
  local origin = originSkillForLongswordRecord(rec)
  if not origin then return end

  local useType    = params.useType
  local gain       = params.skillGain
  local scale      = params.scale

  params.skillGain = 0 -- cancel LB gain (works regardless of handler order)

  _rerouteGuard    = true
  I.SkillProgression.skillUsed(origin, {
    useType   = useType or I.SkillProgression.SKILL_USE_TYPES.Weapon_SuccessfulHit,
    skillGain = gain, -- may be nil (engine computes)
    scale     = scale,
  })
  _rerouteGuard = false
end)

-- ---------- Engine / Events ----------
return {
  engineHandlers = {
    onSave = function()
      return {
        lastApplied = lastApplied,
      }
    end,

    -- Called when a save is loaded; receives whatever we returned from onSave for that save
    onLoad = function(saved)
      local delta = saved.lastApplied

      if math.abs(delta) > 0.0001 then
        longBlade.modifier = longBlade.modifier - delta
        dbg('[OHS][PLAYER]', 'onLoad: subtracted LB_delta =', delta)
      else
        dbg('[OHS][PLAYER]', 'onLoad: LB_delta absent or 0 (no change)')
      end

      -- Reset our session counters; poller will re-derive if a stand-in is equipped.
      setLastApplied(0)
      _bridge.lastApplied = 0
      _bridge.active = false
      _bridge.origin = nil
    end,

    onFrame = enforceThrustForSpears,
    onUpdate = function(_dt)
      if core.isWorldPaused() then return end

      pollStance()
      pollSkillBridge()
      enforceThrustForSpears()
    end,
  },

  eventHandlers = {
    UiModeChanged   = UiModeChanged,
    OHS_LocalEquip  = equipWeapon,
    OHS_ShowMessage = function(data)
      local text = (type(data) == 'string') and data or (data and data.text) or nil
      if text and #text > 0 then ui.showMessage(text) end
    end,
  },
}
