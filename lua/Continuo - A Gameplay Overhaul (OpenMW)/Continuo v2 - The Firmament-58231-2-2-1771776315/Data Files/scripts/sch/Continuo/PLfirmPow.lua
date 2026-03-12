local types = require("openmw.types")
local self  = require("openmw.self")
local core  = require("openmw.core")

local Actor = types.Actor

local TRIGGER_ID = "sch_continuo_sp_app01"

-- Burst configuration
local RECORD_IDS = {
  "sch_continuo_ac_app01",
  "sch_continuo_ac_app02",
  "sch_continuo_ac_app03",
}

local BURST_INTERVAL = 0.25
local BURST_LOOPS = 20

-- State
local wasActive = false
local burstIndex = 0
local burstTimer = 0
local burstActive = false
local burstLoopCount = 0

return {
  engineHandlers = {
    onUpdate = function(dt)

      local isActive = Actor.activeSpells(self):isSpellActive(TRIGGER_ID)

      -- Start burst on inactive -> active transition
      if isActive and not wasActive then
        burstActive = true
        burstIndex = 1
        burstTimer = 0
        burstLoopCount = 0
      end

      wasActive = isActive

      if burstActive then
        burstTimer = burstTimer + dt

        if burstTimer >= BURST_INTERVAL then
          burstTimer = burstTimer - BURST_INTERVAL

          core.sendGlobalEvent("SCH_SpawnAtPlayer", {
            recordId = RECORD_IDS[burstIndex],
          })

          burstIndex = burstIndex + 1

          -- Finished one full 3-ID cycle
          if burstIndex > #RECORD_IDS then
            burstIndex = 1
            burstLoopCount = burstLoopCount + 1

            if burstLoopCount >= BURST_LOOPS then
              burstActive = false
            end
          end
        end
      end

    end
  }
}