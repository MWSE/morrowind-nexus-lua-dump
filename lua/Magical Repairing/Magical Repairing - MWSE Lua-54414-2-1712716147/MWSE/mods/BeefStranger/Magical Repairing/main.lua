local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

require("BeefStranger.Magical Repairing.repairOnTargetEffect")
require("BeefStranger.Magical Repairing.repairArmorEffect")
require("BeefStranger.Magical Repairing.repairWeaponEffect")


-- The function to call on the initialized event.
local function initialized() -- 1.

  -- Print a "Ready!" statement to the MWSE.log file.
  print("[MWSE:Magical Repairing") --2.
end

-- Register our initialized function to the initialized event.

local spellIds = {
  bsRepairTarget = "bsRepairTarget",
  bsRepairArmor = "bsRepairArmor",
  bsRepairWeapon = "bsRepairWeapon"
}
--TODO: make magnitude determine how much. --Cant figure out how to get magnitude :(
local function registerSpells()
  framework.spells.createBasicSpell({
    id = spellIds.bsRepairTarget,
    name = "Repair Target",
    effect = tes3.effect.bsRepairTarget,
    range = tes3.effectRange["target"],
    min = 50,
    max = 50
  })
  framework.spells.createBasicSpell({
    id = spellIds.bsRepairArmor,
    name = "Repair Armor",
    effect = tes3.effect.bsRepairArmor,
    range = tes3.effectRange["self"],
    min = 50,
    max = 50,
    duration = 0
  })
  framework.spells.createBasicSpell({
    id = spellIds.bsRepairWeapon,
    name = "Repair Weapon",
    effect = tes3.effect.bsRepairWeapon,
    range = tes3.effectRange["self"],
    min = 50,
    max = 50,
    duration = 0
  })
end

local function addSpells()
  -- local wasAdded = nil
  -- if (wasAdded == nil) then
    local wasAdded = tes3.addSpell({ reference = "orrent geontene", spell = "bsRepairTarget"})
    local wasAdded = tes3.addSpell({ reference = "orrent geontene", spell = "bsRepairArmor"})
    local wasAdded = tes3.addSpell({ reference = "orrent geontene", spell = "bsRepairWeapon"})
  -- end
end

event.register(tes3.event.loaded, addSpells)
event.register("MagickaExpanded:Register", registerSpells)
event.register(tes3.event.initialized, initialized) --3.