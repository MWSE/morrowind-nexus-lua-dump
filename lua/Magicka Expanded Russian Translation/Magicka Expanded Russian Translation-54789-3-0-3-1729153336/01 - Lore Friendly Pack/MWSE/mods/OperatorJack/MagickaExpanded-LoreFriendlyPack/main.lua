local framework = require("OperatorJack.MagickaExpanded")

local spellIds = {
    banishDaedra = "OJ_ME_BanishDaedraSpell",
    boundGreaves = "OJ_ME_BoundGreavesSpell",
    boundPauldrons = "OJ_ME_BoundPauldronsSpell",
    boundClaymore = "OJ_ME_BoundClaymoreSpell",
    boundClub = "OJ_ME_BoundClubSpell",
    boundDaiKatana = "OJ_ME_BoundDaiKatanaSpell",
    boundKatana = "OJ_ME_BoundKatanaSpell",
    boundShortSword = "OJ_ME_BoundShortswordSpell",
    boundStaff = "OJ_ME_BoundStaffSpell",
    boundTanto = "OJ_ME_BoundTantoSpell",
    boundWakizashi = "OJ_ME_BoundWakizashiSpell",
    boundWarAxe = "OJ_ME_BoundWarAxeSpell",
    boundWarhammer = "OJ_ME_BoundWarhammerSpell"
}

local tomes = {
    {id = "OJ_ME_TomeBanishDaedra", spellId = spellIds.banishDaedra},
    {id = "OJ_ME_TomeBoundGreaves", spellId = spellIds.boundGreaves},
    {id = "OJ_ME_TomeBoundPauldrons", spellId = spellIds.boundPauldrons},
    {id = "OJ_ME_TomeBoundClaymore", spellId = spellIds.boundClaymore},
    {id = "OJ_ME_TomeBoundClub", spellId = spellIds.boundClub},
    {id = "OJ_ME_TomeBoundDaiKatana", spellId = spellIds.boundDaiKatana},
    {id = "OJ_ME_TomeBoundKatana", spellId = spellIds.boundKatana},
    {id = "OJ_ME_TomeBoundShortsword", spellId = spellIds.boundShortSword},
    {id = "OJ_ME_TomeBoundStaff", spellId = spellIds.boundStaff},
    {id = "OJ_ME_TomeBoundTanto", spellId = spellIds.boundTanto},
    {id = "OJ_ME_TomeBoundWakizashi", spellId = spellIds.boundWakizashi},
    {id = "OJ_ME_TomeBoundWaraxe", spellId = spellIds.boundWarAxe},
    {id = "OJ_ME_TomeBoundWarhammer", spellId = spellIds.boundWarhammer}
}

event.register(tes3.event.initialized, function()
    require("OperatorJack.MagickaExpanded-LoreFriendlyPack.effects")

    local listId = "OJ_ME_LeveledList_Common"
    local list = tes3.getObject(listId) --[[@as tes3leveledItem]]
    for _, tome in pairs(tomes) do
        local item = tes3.getObject(tome.id)
        list:insert(item, 1)
    end
end)

local function registerSpells()
    framework.spells.createBasicSpell({
        id = spellIds.banishDaedra,
        name = "Изгнание даэдра",
        distribute = true,
        effect = tes3.effect.banishDaedra,
        rangeType = tes3.effectRange.touch,
        min = 30,
        max = 50
    })
    framework.spells.createBasicSpell({
        id = spellIds.boundGreaves,
        name = "Призвать поножи",
        distribute = true,
        effect = tes3.effect.boundGreaves,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createComplexSpell({
        id = spellIds.boundPauldrons,
        name = "Призвать наплечники",
        distribute = true,
        effects = {
            [1] = {
                id = tes3.effect.boundLeftPauldron,
                rangeType = tes3.effectRange.self,
                duration = 30
            },
            [2] = {
                id = tes3.effect.boundRightPauldron,
                rangeType = tes3.effectRange.self,
                duration = 30
            }
        }
    })
    framework.spells.createBasicSpell({
        id = spellIds.boundClaymore,
        name = "Призвать клеймору",
        distribute = true,
        effect = tes3.effect.boundClaymore,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.boundClub,
        name = "Призвать дубину",
        distribute = true,
        effect = tes3.effect.boundClub,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.boundDaiKatana,
        name = "Призвать дайкатану",
        distribute = true,
        effect = tes3.effect.boundDaiKatana,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.boundKatana,
        name = "Призвать катану",
        distribute = true,
        effect = tes3.effect.boundKatana,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.boundShortSword,
        name = "Призвать короткий меч",
        distribute = true,
        effect = tes3.effect.boundShortSword,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.boundStaff,
        name = "Призвать посох",
        distribute = true,
        effect = tes3.effect.boundStaff,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.boundTanto,
        name = "Призвать танто",
        distribute = true,
        effect = tes3.effect.boundTanto,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.boundWakizashi,
        name = "Призвать вакидзаси",
        distribute = true,
        effect = tes3.effect.boundWakizashi,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.boundWarAxe,
        name = "Призвать топор",
        distribute = true,
        effect = tes3.effect.boundWarAxe,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.boundWarhammer,
        name = "Призвать боевой молот",
        distribute = true,
        effect = tes3.effect.boundWarhammer,
        rangeType = tes3.effectRange.self,
        duration = 30
    })

    framework.tomes.registerTomes(tomes)
end

event.register("MagickaExpanded:Register", registerSpells)
