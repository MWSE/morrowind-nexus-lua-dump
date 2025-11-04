-- GRIP Repair (hotkey-only) — OpenMW 0.49
-- Press P to restore Long Blade to BASE (clears stuck modifier and damage).
-- Uses: input.isKeyPressed + input.KEY.P, and types.NPC.stats.skills.longblade fields.

local self  = require('openmw.self')
local types = require('openmw.types')
local ui    = require('openmw.ui')
local input = require('openmw.input')

local KEY = input.KEY  -- key codes enum (0.49)

-- Pretty print a one-line diagnostic
local function report(prefix, loud)
  local lb       = types.NPC.stats.skills.longblade(self)
  local base     = math.floor((lb.base or 0) + 0.5)
  local damage   = math.floor((lb.damage or 0) + 0.5)
  local modifier = math.floor((lb.modifier or 0) + 0.5)
  local modified = math.floor(base + (lb.modifier or 0) - (lb.damage or 0) + 0.5)
  local msg = string.format("%s LB base=%d, damage=%d, modifier=%d, modified=%d",
                            prefix, base, damage, modifier, modified)
  if loud then ui.showMessage(msg) end
  print("[GRIP]", msg)
end

-- The repair itself: set Long Blade to base
local function repairLongBlade()
  report("Before repair:", true)

  local lb = types.NPC.stats.skills.longblade(self)
  -- Only these two are writable; 'modified' is read-only.
  lb.modifier = 0
  lb.damage   = 0

  report("After repair:", true)
  ui.showMessage("GRIP Repair: Long Blade restored to base.")
end

-- Simple edge detector so holding P doesn’t spam
local wasDown = false

return {
  engineHandlers = {
    onUpdate = function(_dt)
      local down = input.isKeyPressed(KEY.P)
      if down and not wasDown then
        repairLongBlade()
      end
      wasDown = down
    end,
  },
}
