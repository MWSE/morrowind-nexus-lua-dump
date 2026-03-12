local core = require("openmw.core")
local self = require("openmw.self")
local ui   = require("openmw.ui")

local BIRTHSIGN_SPELL_IDS = {
  "blessed word",
  "blessed touch",
  "mara's gift",
  "beggar's nose spell",
  "tower key",
  "moonshadow",
  "star-curse",
  "lover's kiss",
  "mooncalf ability",
  "blood of the north",
  "trollkin ability",
  "wombburn",
  "lady's favor",
  "lady's grace",
  "charioteer ability",
  "fay ability",
  "elfborn ability",
  "akaviri danger-sense",
  "warwyrd ability",
}

local PERIOD = 15
local SECONDS_PER_DAY = 86400

-- run immediately after load
local acc = PERIOD

local warned = false
local faded  = false

-- Suppress UI messages on initial load pass
local suppressMessages = true

local function stripBirthsignSpells()
  local spells = self.type.spells(self)
  if not spells then return false end

  local removedAny = false

  for i = 1, #BIRTHSIGN_SPELL_IDS do
    local id = BIRTHSIGN_SPELL_IDS[i]
    local ok = pcall(function()
      spells:remove(id)
    end)
    -- If remove didn't error, we consider it "successful attempt".
    -- We can't reliably detect ownership in your build (no spells:has), so we latch on any successful pass.
    if ok then
      removedAny = true
    end
  end

  return removedAny
end

return {
  engineHandlers = {
    onUpdate = function(dt)
      if faded then return end

      acc = acc + dt
      if acc < PERIOD then return end
      acc = acc - PERIOD

      local dayIndex = math.floor(core.getGameTime() / SECONDS_PER_DAY)

      if (not warned) and dayIndex >= 6 then
        if not suppressMessages then
          ui.showMessage("Powers granted by your Birthsign will fade soon")
        end
        warned = true
      end

      if dayIndex >= 7 then
        if not suppressMessages then
          ui.showMessage("Powers granted by your Birthsign have faded")
        end

        -- If removal succeeds, disable script for rest of session
        local success = stripBirthsignSpells()
        if success then
          faded = true
        end
      end

      -- After first execution cycle, allow messages normally
      suppressMessages = false
    end
  }
}