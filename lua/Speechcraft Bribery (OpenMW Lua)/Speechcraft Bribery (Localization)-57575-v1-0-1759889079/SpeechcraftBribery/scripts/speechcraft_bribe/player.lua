-- scripts/speechcraft_bribe/player.lua
-- OpenMW 0.49 — Speechcraft Bribe: player-side glue
-- Creature-safe + Dialogue-return-safe + XP reward with configurable scaling.
-- Plays "Item Gold Down" on accepted bribes that actually take gold.

local self    = require('openmw.self')
local async   = require('openmw.async')
local input   = require('openmw.input')
local types   = require('openmw.types')
local core    = require('openmw.core')
local I       = require('openmw.interfaces')
local ambient = require('openmw.ambient')

local settings = require('scripts.speechcraft_bribe.settings')
local Core     = require('scripts.speechcraft_bribe.bribe_core')
local State    = require('scripts.speechcraft_bribe.state')
local BribeUI  = require('scripts.speechcraft_bribe.ui')

-- Track current UI mode and (NPC) dialogue target.
local currentMode = I.UI.getMode()
local dialogueTarget = nil

-- Prevent duplicate trigger handlers after save/load.
local handlerGen = 0

-- Helpers ---------------------------------------------------------------------

local function isNpc(obj)
  return obj and obj.isValid and obj:isValid() and types.NPC.objectIsInstance(obj)
end

local function inDialogueWithNpc()
  return I.UI.getMode() == I.UI.MODE.Dialogue and isNpc(dialogueTarget)
end

local function getName(obj)
  if not (obj and obj.isValid and obj:isValid()) then return "<invalid>" end
  local rec
  if types.NPC.objectIsInstance(obj) then
    rec = types.NPC.record(obj)
  elseif types.Creature and types.Creature.objectIsInstance(obj) then
    rec = types.Creature.record(obj)
  end
  return (rec and rec.name) or obj.recordId or "<unknown>"
end

local function getStatTriplet(actor)
  local speechcraft = types.NPC.stats.skills.speechcraft(actor)
  local mercantile  = types.NPC.stats.skills.mercantile(actor)
  local personality = types.Actor.stats.attributes.personality(actor)

  local p = (speechcraft and speechcraft.modified) or (speechcraft.base + speechcraft.modifier)
  local m = (mercantile  and mercantile.modified)  or (mercantile.base  + mercantile.modifier)
  local a = (personality and personality.modified) or (personality.base + personality.modifier)

  return { speechcraft = p, mercantile = m, personality = a }
end

local function getGoldCount(actor)
  local inv = types.Actor.inventory(actor)
  local cnt = inv:countOf(settings.goldRecordId)
  return cnt or 0
end

local function show(msg)
  self:sendEvent('ShowMessage', { message = msg })
end

-- Input trigger registration ---------------------------------------------------

local function ensureTrigger()
  if not input.triggers[settings.hotkeyName] then
    input.registerTrigger {
      key = settings.hotkeyName,
      l10n = settings.l10n,
      name = settings.hotkeyName_L10N,
      description = settings.hotkeyDesc_L10N,
    }
  end

  handlerGen = handlerGen + 1
  local myGen = handlerGen

  input.registerTriggerHandler(settings.hotkeyName, async:callback(function()
    if myGen ~= handlerGen then return end
    if settings.refreshFromStorage then settings.refreshFromStorage() end

    local mode = I.UI.getMode()
    if mode == I.UI.MODE.Dialogue and not isNpc(dialogueTarget) then
      show("Bribe: Only works on NPCs.")
      return
    end

    if not inDialogueWithNpc() then
      show("Bribe: Only usable during dialogue.")
      return
    end

    local entry = State.read(dialogueTarget)
    if entry.triesLeft <= 0 then
      show("Bribe: No tries left. Come back later.")
      return
    end

    BribeUI.open(
      getName(dialogueTarget),
      entry.triesLeft,
      (entry.inflation or 1) * 100 - 100,
      getGoldCount(self),
      ""
    )
  end))
end

-- XP helpers ------------------------------------------------------------------

local function xpScaleForZone(zone)
  if zone == 'critical' then
    return settings.xpScaleCritical or 1.0
  elseif zone == 'overpay' then
    return settings.xpScaleOverpay or 1.0
  elseif zone == 'success' then
    return settings.xpScaleSuccess or 1.0
  else
    return 0.0
  end
end

local function grantBribeXP(result)
  local zone = result and result.zone
  if not (zone == 'success' or zone == 'critical' or zone == 'overpay') then return end
  local scale = xpScaleForZone(zone)
  if not scale or scale <= 0 then return end

  I.SkillProgression.skillUsed('mercantile', {
    useType = I.SkillProgression.SKILL_USE_TYPES.Mercantile_Bribe,
    scale = scale,
  })
  I.SkillProgression.skillUsed('speechcraft', {
    useType = I.SkillProgression.SKILL_USE_TYPES.Speechcraft_Success,
    scale = scale,
  })
end

-- UI callbacks ----------------------------------------------------------------

BribeUI.onSubmit = function(offer)
  if I.UI.getMode() == I.UI.MODE.Dialogue and not isNpc(dialogueTarget) then
    BribeUI.update(getName(dialogueTarget), "", "", getGoldCount(self), "Bribe is for NPCs only.")
    return
  end
  if not inDialogueWithNpc() then
    BribeUI.update("", "", "", getGoldCount(self), "Not in dialogue.")
    return
  end

  local entry = State.read(dialogueTarget)
  if entry.triesLeft <= 0 then
    BribeUI.update(getName(dialogueTarget), entry.triesLeft, (entry.inflation or 1) * 100 - 100, getGoldCount(self), "No tries left.")
    return
  end

  local gold = getGoldCount(self)

  local pstats = getStatTriplet(self)
  local nstats = getStatTriplet(dialogueTarget)

  local result = Core.evaluateAttempt {
    offer = offer,
    inflation = entry.inflation or 1.0,
    playerStats = pstats,
    npcStats = nstats,
    npc = dialogueTarget,
  }

  local status = Core.formatZoneMessage(result.zone)

  if result.goldTaken > 0 and gold < result.goldTaken then
    BribeUI.update(getName(dialogueTarget), entry.triesLeft, (entry.inflation or 1) * 100 - 100, gold, "Not enough gold.")
    return
  end

  -- Apply state changes
  if result.triesConsumed then
    entry = State.consumeTry(dialogueTarget)
  end
  if result.goldTaken > 0 then
    entry = State.onSuccess(dialogueTarget, result.inflationDelta)
  end

  -- Award XP on accepted bribes (scaled via settings)
  grantBribeXP(result)

  -- Play gold-down sound for accepted bribes that actually remove gold
  if (result.zone == 'success' or result.zone == 'critical' or result.zone == 'overpay') and (result.goldTaken or 0) > 0 then
    ambient.playSound("Item Gold Down")
  end

  local npcName    = getName(dialogueTarget)
  local inflPct    = (entry.inflation or 1) * 100 - 100
  local playerGold = gold - (result.goldTaken or 0)

  if result.goldTaken > 0 or result.dispDelta ~= 0 then
    core.sendGlobalEvent('SpeechcraftBribe_ApplyEffects', {
      npc = dialogueTarget,
      player = self,
      goldTaken = result.goldTaken,
      dispDelta = result.dispDelta,
      message = status,
    })
  else
    show(status)
  end

  BribeUI.update(npcName, entry.triesLeft, inflPct, playerGold, status)
end

-- Script registration ----------------------------------------------------------

return {
  interfaceName = settings.mod .. ".player",
  interface = {},
  eventHandlers = {
    UiModeChanged = function(data)
      local newMode = (data and data.newMode) or I.UI.getMode()
      currentMode = newMode

      if newMode == I.UI.MODE.Dialogue then
        local arg = data and data.arg
        if isNpc(arg) then
          dialogueTarget = arg
        else
          dialogueTarget = nil
        end
      else
        BribeUI.close()
        if newMode == nil then
          dialogueTarget = nil
        end
      end
    end,
  },
  engineHandlers = {
    onInit = function()
      ensureTrigger()
      if settings.refreshFromStorage then settings.refreshFromStorage() end
    end,
    onSave = function()
      if State.serialize then return State.serialize() end
    end,
    onLoad = function(savedData)
      if State.deserialize then State.deserialize(savedData) end
      ensureTrigger()
      if settings.refreshFromStorage then settings.refreshFromStorage() end
      BribeUI.close()
    end,
  },
}
