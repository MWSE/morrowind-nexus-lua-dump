local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
local log = require("chantox.LeechFx.log")

-- Check Magicka Expanded framework.
if (framework == nil) then
    log:error("Magicka Expanded framework is not installed!")
    return
end

local ingredients = {
    ["ingred_vampire_dust_01"] = {[1] = tes3.effect.healthLeech},
    ["ingred_gravetar_01"] = {[2] = tes3.effect.healthLeech},
    ["ingred_hound_meat_01"] = {[3] = tes3.effect.healthLeech},
    ["ingred_ghoul_heart_01"] = {[4] = tes3.effect.healthLeech},
    ["ingred_ash_salts_01"] = {[4] = tes3.effect.magickaLeech},
    ["ingred_daedra_skin_01"] = {[4] = tes3.effect.magickaLeech}
}

local trainers = {
    ["gildan"] = {"LFx_Lesser_HVamp", "LFx_Lesser_FVamp"},
    ["llaros uvayn"] = {"LFx_Lesser_HVamp", "LFx_Lesser_FVamp"},
    ["minnibi selkin-adda"] = {"LFx_Lesser_HVamp", "LFx_Lesser_FVamp"},
    ["ranis athrys"] = {"LFx_Minor_HVamp", "LFx_Minor_FVamp"},
    ["salam andrethi"] = {"LFx_Minor_HVamp", "LFx_Minor_FVamp"},
    ["ethasi rilvayn"] = {"LFx_Major_HVamp", "LFx_Minor_HVamp", "LFx_Minor_FVamp"},
}

local function registerEnchantments()
    -- Shield of the Undaunted
    framework.enchantments.createBasicEnchantment({
        id = "leechfx_undaunted",
        effect = tes3.effect.fatigueLeech,
        min = 15,
        max = 15,
        castType = tes3.enchantmentType.constant
    })

    -- Wings of the Queen of Bats
    framework.enchantments.createBasicEnchantment({
        id = "leechfx_queen_of_bats",
        effect = tes3.effect.healthLeech,
        min = 35,
        max = 35,
        castType = tes3.enchantmentType.constant
    })
end

local function registerSpells()
    -- Health
    framework.spells.createBasicSpell{
        id = "LFx_Lesser_HVamp",
        name = "Leaching Strikes",
        effect = tes3.effect.healthLeech,
        range = tes3.effectRange.self,
        min = 6,
        max = 12,
        duration = 20,
    }

    framework.spells.createBasicSpell{
        id = "LFx_Minor_HVamp",
        name = "Greater Leaching Strikes",
        effect = tes3.effect.healthLeech,
        range = tes3.effectRange.self,
        min = 10,
        max = 20,
        duration = 25,
    }

    framework.spells.createBasicSpell{
        id = "LFx_Major_HVamp",
        name = "Vampiric Dirge",
        effect = tes3.effect.healthLeech,
        range = tes3.effectRange.self,
        min = 15,
        max = 20,
        duration = 60,
    }

    -- Fatigue
    framework.spells.createBasicSpell{
        id = "LFx_Lesser_FVamp",
        name = "Restoring Strikes",
        effect = tes3.effect.fatigueLeech,
        range = tes3.effectRange.self,
        min = 4,
        max = 8,
        duration = 30,
    }

    framework.spells.createBasicSpell{
        id = "LFx_Minor_FVamp",
        name = "Rejuvenating Strikes",
        effect = tes3.effect.fatigueLeech,
        range = tes3.effectRange.self,
        min = 6,
        max = 12,
        duration = 60,
    }
end

local function setIngredientEffects()
    for id, effects in pairs(ingredients) do
        local ingredient = tes3.getObject(id)
        if ingredient then
            for i, effect in pairs(effects) do
                ingredient.effects[i] = effect
            end
        end
    end

end

local function addVendorSpells()
    for id, spells in pairs(trainers) do
        local npc = tes3.getReference(id)
        if npc then
            for _, spell in pairs(spells) do
                tes3.addSpell{
                    reference = npc,
                    spell = spell
                }
            end
        end
    end
end

local function onRegister()
    setIngredientEffects()
    registerEnchantments()
    registerSpells()
    addVendorSpells()
end

local function onInitialized()
    event.register("MagickaExpanded:Register", onRegister)

    log:info("Implementations module initialized.")
end
event.register(tes3.event.initialized, onInitialized)
