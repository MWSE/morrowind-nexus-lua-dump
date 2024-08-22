local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

require("Syanide.Disarm Spell.disarmTarget")


-- The function to call on the initialized event.
local function initialized() -- 1.

  -- Print a "Ready!" statement to the MWSE.log file.
  print("[Disarm Spell] Initialized!") --2.
end

-- Register our initialized function to the initialized event.

local spellIds = {
  disarmTarget = "disarmTarget"
}
--TODO: make magnitude determine how much. --Cant figure out how to get magnitude :(
local function registerSpells()
  framework.spells.createBasicSpell({
    id = spellIds.disarmTarget,
    name = "Disarm Trap",
    effect = tes3.effect.disarmTarget,
    range = tes3.effectRange["target"],
    min = 20,
    max = 20
  })
end

local function addSpells()
  -- local wasAdded = nil
  -- if (wasAdded == nil) then
    local wasAdded = tes3.addSpell({ reference = "j'rasha", spell = "disarmTarget"})
  -- end
end

event.register(tes3.event.loaded, addSpells)
event.register("MagickaExpanded:Register", registerSpells)
event.register(tes3.event.initialized, initialized) --3.