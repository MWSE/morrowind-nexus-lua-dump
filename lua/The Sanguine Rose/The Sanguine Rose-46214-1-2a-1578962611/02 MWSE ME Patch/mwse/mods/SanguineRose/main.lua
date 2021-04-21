local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
if (framework == nil) then
    local function warning()
        tes3.messageBox(
            "[The Sanguine Rose ERROR] Magicka Expanded framework is not installed!"
            .. " You will need to install it to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end

require("SanguineRose.effects.sanguineRose")

-- Register Enchantment --
local function registerEnchantments()
  framework.enchantments.createBasicEnchantment({
    id = "mdSR_en_sanguine rose",
    effect = tes3.effect.sanguineRose,
    range = tes3.effectRange.self,
    duration = 60,
    chargeCost = 500,
    maxCharge = 5000,
	  castType = tes3.enchantmentType.onUse
  })
end
  
 event.register("MagickaExpanded:Register", registerEnchantments)