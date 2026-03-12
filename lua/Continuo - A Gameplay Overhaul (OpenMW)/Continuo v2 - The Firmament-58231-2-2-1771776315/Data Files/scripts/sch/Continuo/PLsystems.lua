local nearby = require("openmw.nearby")
local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")
local types = require("openmw.types")
local util = require("openmw.util")

local Actor = types.Actor
local NPC = types.NPC
local Creature = types.Creature

-- =========================
-- Pre-localize for speed
-- =========================
local find = string.find
local lower = string.lower
local random = math.random
local max = math.max

-- =========================
-- Sleep gating (beds)
-- =========================
local THRESH2 = 250 * 250
local NOSLEEP_TAG = "NoSleep"

-- =========================
-- Dialogue pause throttle
-- =========================
local dialogueAcc = 0
local DIALOGUE_PERIOD = 0.5
local cachedDialoguePause = false
local lastDialoguePause = nil

-- =========================
-- Barter block throttle
-- =========================
local BARTER_BLOCK_RANGE2 = 250 * 250
local BARTER_BLOCK_IDS = {
  ["mudcrab_unique"] = true,
  ["scamp_creeper"]  = true,
}
local barterAcc = 0
local BARTER_PERIOD = 0.2

-- =========================
-- Death throttle
-- =========================
local acc = 0
local PERIOD = 0.5
local latched = false

local pauseConfigured = false

-- =========================
-- Utilities
-- =========================
local function dist2(a, b)
  local dx = b.x - a.x
  local dy = b.y - a.y
  local dz = b.z - a.z
  return dx*dx + dy*dy + dz*dz
end

local function isNPCOrCreature(o)
  return o and (
    NPC.objectIsInstance(o)
    or (Creature and Creature.objectIsInstance and Creature.objectIsInstance(o))
  )
end

-- =========================
-- Sleep gating helpers (RESTORED)
-- =========================
local function isBedActivator(acti)
  -- record() is expensive; caller should distance-gate first
  local record = acti and acti.type and acti.type.record and acti.type.record(acti)
  if not record then return false end

  -- Fast path: mwscript bed_*
  local mwrec = record.mwscript
  if type(mwrec) == "string" and find(mwrec, "^bed_") then
    return true
  end

  -- Fallback: record id contains "bed"
  local rid = record.id
  if type(rid) == "string" and find(lower(rid), "bed", 1, true) then
    return true
  end

  return false
end

local function allowedToSleep()
  -- If in a NoSleep-tagged cell, allow resting (matches original behavior)
  local cell = self.cell
  if cell and cell.hasTag and cell:hasTag(NOSLEEP_TAG) then
    return true
  end

  local ppos = self.position
  local acts = nearby.activators or {}

  for i = 1, #acts do
    local acti = acts[i]
    if acti and acti.position and dist2(ppos, acti.position) < THRESH2 then
      if isBedActivator(acti) then
        return true
      end
    end
  end

  return false
end

-- =========================
-- Guard class (lowercase)
-- =========================
local function isGuardClass(actorObj)
  if not actorObj or not NPC.objectIsInstance(actorObj) then return false end
  local rec = NPC.record(actorObj)
  if not rec then return false end
  local cls = rec.class
  return (type(cls) == "string") and (lower(cls) == "guard")
end

-- =========================
-- Dialogue guard+bounty
-- =========================
local function allowDialoguePause()
  local bounty = self.type.getCrimeLevel(self) or 0
  if bounty <= 0 then return false end

  local ppos = self.position
  local actors = nearby.actors or {}

  for i = 1, #actors do
    local a = actors[i]
    if isNPCOrCreature(a) then
      if dist2(ppos, a.position) <= (500 * 500) then
        if isGuardClass(a) then
          return true
        end
      end
    end
  end

  return false
end

local function setDialoguePause(on)
  I.UI.setPauseOnMode("Dialogue", on)
end

-- =========================
-- Barter block logic
-- =========================
local function nearBarterBlockedMerchant()
  local ppos = self.position
  local actors = nearby.actors or {}

  for i = 1, #actors do
    local a = actors[i]
    if isNPCOrCreature(a) then
      if dist2(ppos, a.position) <= BARTER_BLOCK_RANGE2 then
        local rec = a.type.record(a) -- works for NPC + Creature
        local rid = rec and rec.id
        if type(rid) == "string" and BARTER_BLOCK_IDS[lower(rid)] then
          return true
        end
      end
    end
  end

  return false
end

local function forceCloseBarterIfNeeded()
  if not nearBarterBlockedMerchant() then return end

  -- robust mode check (case-insensitive)
  local mode = (I.UI.getMode and I.UI.getMode()) or nil
  if type(mode) == "string" and lower(mode) == "barter" then
    I.UI.removeMode(mode)
  end
end

-- =========================
-- Death logic
-- =========================
local SPELL_ID = "sch_continuo_sp_die"

local RESPAWNS = {
  { cell = "Seyda Neen, Arrille's Tradehouse", pos = util.vector3(-66, -7, 405) },
  { cell = "Maar Gan, Shrine", pos = util.vector3(-3093, 1356, 769) },
  { cell = "Ebonheart, Six Fishes", pos = util.vector3(249, 299, 29) },
  { cell = "Sadrith Mora, Wolverine Hall: Imperial Shrine", pos = util.vector3(-75, 304, -97) },
  { cell = "Molag Mar, St. Veloth's Hostel", pos = util.vector3(3903, 4314, 15296) },
  { cell = "Khuul, Thongar's Tradehouse", pos = util.vector3(4505, 4138, 13741) },
}

local function pickRespawn()
  local n = #RESPAWNS
  if n == 0 then return nil end
  return RESPAWNS[random(n)]
end

local function weightedLoss(minLoss, maxLoss)
  if random(10) <= 8 then return 0 end
  return random(minLoss, maxLoss)
end

local function decAttribute(key)
  local stat = Actor.stats.attributes[key](self)
  local loss = weightedLoss(1, 3)
  if loss > 0 then
    stat.base = max(0, stat.base - loss)
  end
end

local function decSkill(key)
  local stat = NPC.stats.skills[key](self)
  local loss = weightedLoss(1, 3)
  if loss > 0 then
    stat.base = max(0, stat.base - loss)
  end
end

local function applyContinuoPenalty()
  local attributes = {
    "strength","intelligence","willpower","agility",
    "speed","endurance","personality","luck"
  }
  for i = 1, #attributes do
    decAttribute(attributes[i])
  end

  local skills = {
    "block","armorer","mediumarmor","heavyarmor","bluntweapon","longblade","axe","spear",
    "athletics","enchant","destruction","alteration","illusion","conjuration","mysticism",
    "restoration","alchemy","unarmored","security","sneak","acrobatics","lightarmor",
    "shortblade","marksman","mercantile","speechcraft","handtohand",
  }
  for i = 1, #skills do
    decSkill(skills[i])
  end
end

-- =========================
-- Engine handlers + UiModeChanged (RESTORED)
-- =========================
return {
  engineHandlers = {

    onActive = function()
      if pauseConfigured then return end
      pauseConfigured = true

      for k, v in pairs(I.UI.MODE) do
        local name = (type(v) == "string") and v or k
        if type(name) == "string" then
          I.UI.setPauseOnMode(name, false)
        end
      end

      lastDialoguePause = false
      cachedDialoguePause = false
      dialogueAcc = 0
      barterAcc = 0
      acc = 0
    end,

    onUpdate = function(dt)
      -- Dialogue pause throttle (0.5s)
      dialogueAcc = dialogueAcc + dt
      if dialogueAcc >= DIALOGUE_PERIOD then
        dialogueAcc = dialogueAcc - DIALOGUE_PERIOD
        cachedDialoguePause = allowDialoguePause()
      end

      if cachedDialoguePause ~= lastDialoguePause then
        setDialoguePause(cachedDialoguePause)
        lastDialoguePause = cachedDialoguePause
      end

      -- Barter enforcement throttle (0.2s)
      barterAcc = barterAcc + dt
      if barterAcc >= BARTER_PERIOD then
        barterAcc = barterAcc - BARTER_PERIOD
        forceCloseBarterIfNeeded()
      end

      -- Death throttle (0.5s)
      acc = acc + dt
      if acc < PERIOD then return end
      acc = acc - PERIOD

      local active = Actor.activeSpells(self)
      local on = active and active:isSpellActive(SPELL_ID)

      if on and not latched then
        latched = true
        applyContinuoPenalty()

        -- IMPORTANT: gold loss + death spell cleanup must happen regardless of branch
        core.sendGlobalEvent("Continuo_ApplyDeathConsequences", {})

        -- 2/3: apply ALMSIVI or DIVINE intervention to player
        -- 1/3: original random respawn teleport behavior
        if random(2) == 1 then
          local spellId = (random(2) == 1) and "almsivi intervention" or "divine intervention"
          Actor.activeSpells(self):add({ id = spellId, effects = { 0 }, caster = self })
          I.UI.showInteractiveMessage("A void surrounds you. Then you wake.")
        else
          local dest = pickRespawn()
          if dest then
            I.UI.showInteractiveMessage("A void surrounds you. Then you wake.")
            core.sendGlobalEvent("Continuo_TeleportPlayer", { cell = dest.cell, pos = dest.pos })
          end
        end

      elseif not on then
        latched = false
      end
    end
  },

  eventHandlers = {
    UiModeChanged = function(data)
      -- Rest gating: if Rest is entered and no bed nearby, close it
      if data and data.newMode == "Rest" then
        if not allowedToSleep() then
          I.UI.removeMode(data.newMode)
        end
        return
      end

      -- Optional fast-path close for barter; the 0.2s poll is the "no soft bypass" layer.
      if data and type(data.newMode) == "string" and lower(data.newMode) == "barter" then
        if nearBarterBlockedMerchant() then
          I.UI.removeMode(data.newMode)
        end
        return
      end
    end
  }
}