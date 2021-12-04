-- Check Magicka Expanded framework --
local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
if (framework == nil) then
    local function warning()
        tes3.messageBox(
            "[Unobtainable Powers ERROR] Magicka Expanded framework is not installed!"
            .. " You will need to install it to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end
----------------------------

local spellIds = {
  burningHand = "burning hand",
  wizardsBrand = "wizard's brand"
}

local tomes = {
  {
    id = "G93_BurningHand",
    spellId = spellIds.burningHand
  }, 
  {
    id = "G93_WizardsBrand",
    spellId = spellIds.wizardsBrand
  }, 
}

local function registerTomes()
  framework.tomes.registerTomes(tomes)
end

event.register("MagickaExpanded:Register", registerTomes)