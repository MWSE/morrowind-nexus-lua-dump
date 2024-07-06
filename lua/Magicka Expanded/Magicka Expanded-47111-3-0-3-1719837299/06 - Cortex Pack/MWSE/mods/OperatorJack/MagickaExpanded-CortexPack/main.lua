local framework = require("OperatorJack.MagickaExpanded")

local spellIds = {
    blink = "OJ_ME_BlinkSpell",
    clone = "OJ_ME_Clone",
    darkShadow = "OJ_ME_DarkShadowSpell",
    veilOfDarkness = "OJ_ME_DarknessSpell",
    mindScan = "OJ_ME_MindScan",
    mindRip = "OJ_ME_MindRip",
    soulScrye = "OJ_ME_SoulScrye",
    coalesce = "OJ_ME_Coalesce",
    permutation = "OJ_ME_Permutation",

    conjurePalmLightning = "OJ_ME_ConjurePalmLightning",
    conjurePalmFrost = "OJ_ME_ConjurePalmFrost",
    conjurePalmFlame = "OJ_ME_ConjurePalmFlame"
}

local tomes = {
    {id = "OJ_ME_TomeBlink", spellId = spellIds.blink, list = "OJ_ME_LeveledList_Rare"},
    {id = "OJ_ME_TomeDarkness", spellId = spellIds.veilOfDarkness, list = "OJ_ME_LeveledList_Rare"},
    {id = "OJ_ME_TomeClone", spellId = spellIds.clone, list = "OJ_ME_LeveledList_Rare"},
    {id = "OJ_ME_TomeMindScan", spellId = spellIds.mindScan, list = "OJ_ME_LeveledList_Rare"},
    {id = "OJ_ME_TomeMindRip", spellId = spellIds.mindRip, list = "OJ_ME_LeveledList_Rare"},
    {id = "OJ_ME_TomeSoulScrye", spellId = spellIds.soulScrye, list = "OJ_ME_LeveledList_Rare"},
    {id = "OJ_ME_TomeCoalesce", spellId = spellIds.coalesce, list = "OJ_ME_LeveledList_Rare"},
    {id = "OJ_ME_TomePermutation", spellId = spellIds.permutation, list = "OJ_ME_LeveledList_Rare"}
}

---@type MagickaExpanded.Distribution.DistributionModel[]
local distributions = {
    {
        spell = spellIds.conjurePalmFlame,
        source = "magicka-expanded-cortex-pack",
        filterRaceId = "dark elf"
    },
    {
        spell = spellIds.conjurePalmFrost,
        source = "magicka-expanded-cortex-pack",
        filterRaceId = "nord"
    }
}

event.register(tes3.event.initialized, function()
    require("OperatorJack.MagickaExpanded-CortexPack.effects")

    for _, tome in pairs(tomes) do
        local item = tes3.getObject(tome.id)
        local list = tes3.getObject(tome.list) --[[@as tes3leveledItem]]
        list:insert(item, 1)
    end
end)

local function registerSpells()
    framework.spells.createBasicSpell({
        id = spellIds.blink,
        name = "Blink",
        distribute = true,
        effect = tes3.effect.blink,
        rangeType = tes3.effectRange.target,
        magickaCost = 35
    })

    framework.spells.createBasicSpell({
        id = spellIds.conjurePalmLightning,
        name = "Conjure Palm Lightning",
        distribute = true,
        effect = tes3.effect.conjurePalmLightning,
        rangeType = tes3.effectRange.self,
        duration = 15,
        min = 10,
        max = 50
    })

    framework.spells.createBasicSpell({
        id = spellIds.conjurePalmFlame,
        name = "Conjure Palm Flame",
        -- distribute = true,
        effect = tes3.effect.conjurePalmFlame,
        rangeType = tes3.effectRange.self,
        duration = 15,
        min = 10,
        max = 50
    })

    framework.spells.createBasicSpell({
        id = spellIds.conjurePalmFrost,
        name = "Conjure Palm Frost",
        -- distribute = true,
        effect = tes3.effect.conjurePalmFrost,
        rangeType = tes3.effectRange.self,
        duration = 15,
        min = 10,
        max = 50
    })

    framework.spells.createBasicSpell({
        id = spellIds.darkShadow,
        name = "Dark Shadow",
        distribute = true,
        effect = tes3.effect.darkness,
        rangeType = tes3.effectRange.self,
        min = 20,
        max = 20,
        duration = 10,
        magickaCost = 62
    })
    framework.spells.createBasicSpell({
        id = spellIds.veilOfDarkness,
        name = "Veil of Darkness",
        distribute = true,
        effect = tes3.effect.darkness,
        rangeType = tes3.effectRange.target,
        min = 50,
        max = 100,
        duration = 10,
        magickaCost = 112
    })

    framework.spells.createBasicSpell({
        id = spellIds.clone,
        name = "Clone",
        distribute = true,
        effect = tes3.effect.clone,
        rangeType = tes3.effectRange.target,
        duration = 10,
        min = 10,
        max = 30,
        magickaCost = 210
    })

    framework.spells.createBasicSpell({
        id = spellIds.mindScan,
        name = "Vondakir's Insight",
        distribute = true,
        effect = tes3.effect.mindScan,
        rangeType = tes3.effectRange.self,
        duration = 10,
        magickaCost = 22
    })

    framework.spells.createBasicSpell({
        id = spellIds.mindRip,
        name = "Vondakir's Intrusion",
        distribute = true,
        effect = tes3.effect.mindRip,
        rangeType = tes3.effectRange.touch,
        magickaCost = 185
    })

    framework.spells.createBasicSpell({
        id = spellIds.soulScrye,
        name = "Vondakir's Scrutiny",
        distribute = true,
        effect = tes3.effect.soulScrye,
        rangeType = tes3.effectRange.self,
        duration = 10,
        magickaCost = 25
    })

    framework.spells.createBasicSpell({
        id = spellIds.coalesce,
        name = "Coalesce",
        distribute = true,
        effect = tes3.effect.coalesce,
        rangeType = tes3.effectRange.target,
        magickaCost = 5
    })

    framework.spells.createBasicSpell({
        id = spellIds.permutation,
        name = "Permutation",
        distribute = true,
        effect = tes3.effect.permutation,
        rangeType = tes3.effectRange.self,
        duration = 30,
        magickaCost = 86
    })

    framework.tomes.registerTomes(tomes)
    -- framework.distribution.registerDistributions(distributions)
end

event.register("MagickaExpanded:Register", registerSpells)
