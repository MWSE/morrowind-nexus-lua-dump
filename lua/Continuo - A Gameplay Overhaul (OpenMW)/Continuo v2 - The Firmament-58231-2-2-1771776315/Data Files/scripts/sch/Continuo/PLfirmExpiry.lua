local core = require("openmw.core")
local self = require("openmw.self")
local ui   = require("openmw.ui")
local storage = require("openmw.storage")
local types = require("openmw.types")

local Actor = types.Actor

local firmStore = storage.globalSection("sch_contfirm")

local PERIOD = 15
local acc = 0

local warned = false
local lastSeenExpiry = nil
local expiredHandled = false

local ALL_FIRM_SPELLS = {
  "sch_continuo_sp_apa01","sch_continuo_sp_apa02","sch_continuo_sp_apa03","sch_continuo_sp_app01",
  "sch_continuo_sp_ata01","sch_continuo_sp_ata02","sch_continuo_sp_ata03","sch_continuo_sp_atp01",
  "sch_continuo_sp_laa01","sch_continuo_sp_laa02","sch_continuo_sp_laa03","sch_continuo_sp_lap01",
  "sch_continuo_sp_lora01","sch_continuo_sp_lora02","sch_continuo_sp_lora03","sch_continuo_sp_lorp01",
  "sch_continuo_sp_loa01","sch_continuo_sp_loa02","sch_continuo_sp_loa03","sch_continuo_sp_lop01",
  "sch_continuo_sp_maa01","sch_continuo_sp_maa02","sch_continuo_sp_maa03","sch_continuo_sp_map01",
  "sch_continuo_sp_ria01","sch_continuo_sp_ria02","sch_continuo_sp_ria03","sch_continuo_sp_rip01",
  "sch_continuo_sp_sea01","sch_continuo_sp_sea02","sch_continuo_sp_sea03","sch_continuo_sp_sep01",
  "sch_continuo_sp_sha01","sch_continuo_sp_sha02","sch_continuo_sp_sha03","sch_continuo_sp_shp01",
  "sch_continuo_sp_sta01","sch_continuo_sp_sta02","sch_continuo_sp_sta03","sch_continuo_sp_stp01",
  "sch_continuo_sp_tha01","sch_continuo_sp_tha02","sch_continuo_sp_tha03","sch_continuo_sp_thp01",
  "sch_continuo_sp_toa01","sch_continuo_sp_toa02","sch_continuo_sp_toa03","sch_continuo_sp_top01",
  "sch_continuo_sp_waa01","sch_continuo_sp_waa02","sch_continuo_sp_waa03","sch_continuo_sp_wap01",
}

-- Powers (one-shot; remove when detected active)
local FIRM_POWERS = {
  "sch_continuo_sp_app01",
  "sch_continuo_sp_atp01",
  "sch_continuo_sp_lap01",
  "sch_continuo_sp_lorp01",
  "sch_continuo_sp_lop01",
  "sch_continuo_sp_map01",
  "sch_continuo_sp_rip01",
  "sch_continuo_sp_sep01",
  "sch_continuo_sp_shp01",
  "sch_continuo_sp_stp01",
  "sch_continuo_sp_thp01",
  "sch_continuo_sp_top01",
  "sch_continuo_sp_wap01",
}

-- Serpent power special message (once per cast window)
local SERPENT_POWER_ID = "sch_continuo_sp_sep01"
local serpentWasActive = false
local serpentMsgShown  = false

-- Early-return condition uses activeSpells (supported in your build)
local function hasAnyActiveFirmSpell()
  local active = Actor.activeSpells(self)
  if not active then return false end

  for i = 1, #ALL_FIRM_SPELLS do
    if active:isSpellActive(ALL_FIRM_SPELLS[i]) then
      return true
    end
  end

  return false
end

local function stripFirmamentSpells()
  local spells = self.type.spells(self)
  if not spells then return end

  for i = 1, #ALL_FIRM_SPELLS do
    pcall(function()
      spells:remove(ALL_FIRM_SPELLS[i])
    end)
  end
end

local function stripActiveFirmamentPowers()
  local active = Actor.activeSpells(self)
  if not active then return end

  local spells = self.type.spells(self)
  if not spells then return end

  -- Serpent: show message once per cast window (while power is active)
  local serpentActive = active:isSpellActive(SERPENT_POWER_ID)
  if not serpentActive then
    serpentWasActive = false
    serpentMsgShown = false
  else
    if not serpentWasActive then
      serpentWasActive = true
      serpentMsgShown = false
    end
    if not serpentMsgShown then
      ui.showMessage("The Serpent devours, and rewards you with two Memory Scrolls.")
      serpentMsgShown = true
    end
  end

  -- Remove any active power spells (one-shot behavior)
  for i = 1, #FIRM_POWERS do
    local id = FIRM_POWERS[i]
    if active:isSpellActive(id) then
      pcall(function()
        spells:remove(id)
      end)
    end
  end
end

return {
  engineHandlers = {
    onUpdate = function(dt)
      acc = acc + dt
      if acc < PERIOD then return end
      acc = acc - PERIOD

      -- Early return: none of the Firmament spells are currently active
      if not hasAnyActiveFirmSpell() then
        warned = false
        lastSeenExpiry = nil
        expiredHandled = false
        serpentWasActive = false
        serpentMsgShown = false
        return
      end

      -- One-shot power cleanup + Serpent message
      stripActiveFirmamentPowers()

      local expiry = firmStore:get("firmExpiryTime")
      local isActive = firmStore:get("firmActive")

      -- If not active, reset local flags
      if not expiry or not isActive then
        warned = false
        lastSeenExpiry = nil
        expiredHandled = false
        return
      end

      -- If a new expiry was set (new attunement), reset warning + expiry latch
      if lastSeenExpiry ~= expiry then
        warned = false
        lastSeenExpiry = expiry
        expiredHandled = false
      end

      local now = core.getGameTime()
      local secondsLeft = expiry - now

      if (not warned) and secondsLeft <= 86400 and secondsLeft > 0 then
        ui.showMessage("The Firmament trembles. Your attunement fades soon.")
        warned = true
      end

      -- One-shot expiry handling
      if now >= expiry then
        if expiredHandled then return end
        expiredHandled = true

        ui.showMessage("The Firmament withdraws its blessing.")
        stripFirmamentSpells()

        warned = false
      end
    end
  }
}