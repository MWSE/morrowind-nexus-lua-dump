local framework = require("OperatorJack.MagickaExpanded")

local spellIds = {
    aldruhn = "OJ_ME_TeleportToAldRuhn",
    balmora = "OJ_ME_TeleportToBalmora",
    ebonheart = "OJ_ME_TeleportToEbonheart",
    vivec = "OJ_ME_TeleportToVivec",

    caldera = "OJ_ME_TeleportToCaldera",
    gnisis = "OJ_ME_TeleportToGnisis",
    maargan = "OJ_ME_TeleportToMaarGan",
    molagmar = "OJ_ME_TeleportToMolagMar",
    pelagiad = "OJ_ME_TeleportToPelagiad",
    suran = "OJ_ME_TeleportToSuran",
    telmora = "OJ_ME_TeleportToTelMora",

    mournhold = "OJ_ME_TeleportToMournhold"
}

local tomes = {
    {id = "OJ_ME_TomeTeleAldRuhn", spellId = spellIds.aldruhn, list = "OJ_ME_LeveledList_Common"},
    {id = "OJ_ME_TomeTeleBalmora", spellId = spellIds.balmora, list = "OJ_ME_LeveledList_Common"},
    {
        id = "OJ_ME_TomeTeleEbonheart",
        spellId = spellIds.ebonheart,
        list = "OJ_ME_LeveledList_Common"
    }, {id = "OJ_ME_TomeTeleVivec", spellId = spellIds.vivec, list = "OJ_ME_LeveledList_Common"},
    {id = "OJ_ME_TomeTeleCaldera", spellId = spellIds.caldera, list = "OJ_ME_LeveledList_Common"},
    {id = "OJ_ME_TomeTeleGnisis", spellId = spellIds.gnisis, list = "OJ_ME_LeveledList_Common"},
    {id = "OJ_ME_TomeTeleMaarGan", spellId = spellIds.maargan, list = "OJ_ME_LeveledList_Common"},
    {id = "OJ_ME_TomeTeleMolagMar", spellId = spellIds.molagmar, list = "OJ_ME_LeveledList_Common"},
    {id = "OJ_ME_TomeTelePelagiad", spellId = spellIds.pelagiad, list = "OJ_ME_LeveledList_Common"},
    {id = "OJ_ME_TomeTeleSuran", spellId = spellIds.suran, list = "OJ_ME_LeveledList_Common"},
    {id = "OJ_ME_TomeTeleTelMora", spellId = spellIds.telmora, list = "OJ_ME_LeveledList_Common"},
    {
        id = "OJ_ME_TomeTeleMournhold",
        spellId = spellIds.mournhold,
        list = "OJ_ME_LeveledList_Common"
    }
}

event.register(tes3.event.initialized, function()
    require("OperatorJack.MagickaExpanded-TeleportationPack.effects.teleportationEffectSet")

    for _, tome in pairs(tomes) do
        local item = tes3.getObject(tome.id)
        local list = tes3.getObject(tome.list) --[[@as tes3leveledItem]]
        list:insert(item, 1)
    end
end)

local function registerSpells()
    framework.spells.createBasicSpell({
        id = spellIds.mournhold,
        name = "Телепорт в Морнхолд",
        distribute = true,
        effect = tes3.effect.teleportToMournhold,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })

    framework.spells.createBasicSpell({
        id = spellIds.aldruhn,
        name = "Телепорт в Альд'рун",
        distribute = true,
        effect = tes3.effect.teleportToAldRuhn,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = spellIds.balmora,
        name = "Телепорт в Балмору",
        distribute = true,
        effect = tes3.effect.teleportToBalmora,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = spellIds.ebonheart,
        name = "Телепорт в Эбенгард",
        distribute = true,
        effect = tes3.effect.teleportToEbonheart,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = spellIds.vivec,
        name = "Телепорт в Вивек",
        distribute = true,
        effect = tes3.effect.teleportToVivec,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = spellIds.caldera,
        name = "Телепорт в Кальдеру",
        distribute = true,
        effect = tes3.effect.teleportToCaldera,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = spellIds.gnisis,
        name = "Телепорт в Гнисис",
        distribute = true,
        effect = tes3.effect.teleportToGnisis,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = spellIds.maargan,
        name = "Телепорт в Маар Ган",
        distribute = true,
        effect = tes3.effect.teleportToMaarGan,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = spellIds.molagmar,
        name = "Телепорт в Молаг Мар",
        distribute = true,
        effect = tes3.effect.teleportToMolagMar,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = spellIds.pelagiad,
        name = "Телепорт в Пелагиад",
        distribute = true,
        effect = tes3.effect.teleportToPelagiad,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = spellIds.suran,
        name = "Телепорт в Суран",
        distribute = true,
        effect = tes3.effect.teleportToSuran,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = spellIds.telmora,
        name = "Телепорт в Тель Мору",
        distribute = true,
        effect = tes3.effect.teleportToTelMora,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })

    framework.tomes.registerTomes(tomes)
end

event.register("MagickaExpanded:Register", registerSpells)
