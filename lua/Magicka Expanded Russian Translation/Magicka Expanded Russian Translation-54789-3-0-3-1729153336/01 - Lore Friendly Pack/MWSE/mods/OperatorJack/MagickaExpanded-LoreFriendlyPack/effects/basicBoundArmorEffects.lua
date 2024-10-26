local framework = require("OperatorJack.MagickaExpanded")

tes3.claimSpellEffectId("boundGreaves", 239)
tes3.claimSpellEffectId("boundLeftPauldron", 240)
tes3.claimSpellEffectId("boundRightPauldron", 264)

local function getPairDescription(armorName)
    return "Этот эффект заклинания вызывает малую Даэдру, скованную в форме магических," ..
    " удивительно легкгих " .. armorName ..". Они немедленно экипируются" ..
    " на заклинателя, перемещая любой экипированный доспех в инвентарь."..
    " Когда эффект " .. armorName .. " заканчивается,  призванный доспех исчезает, а тот, которым пользовался заклинатель вначале, автоматически экипируется."
end
local function getSingleDescription(armorName)
    return "Этот эффект заклинания вызывает малую Даэдру, скованную в форме магического," ..
    " удивительно легкого " .. armorName ..". Он немедленно экипируется" ..
    " на заклинателя, перемещая любой экипированный доспех в инвентарь. "..
    " Когда эффект " .. armorName .. " заканчивается,  призванный доспех исчезает, а тот, которым пользовался заклинатель вначале, автоматически экипируется."
end

framework.effects.conjuration.createBasicBoundArmorEffect({
    id = tes3.effect.boundGreaves,
    name = "Призвать поножи",
    description = getPairDescription("Даэдрических поножн"),
    baseCost = 2,
    armorId = "OJ_ME_BoundGreaves",
    icon = "RFD\\RFD_lf_greaves.dds"
})
framework.effects.conjuration.createBasicBoundArmorEffect({
    id = tes3.effect.boundLeftPauldron,
    name = "Призвать левый наплечник",
    description = getSingleDescription("Даэдрического левого наплечника"),
    baseCost = 2,
    armorId = "OJ_ME_BoundPauldronLeft",
    icon = "RFD\\RFD_lf_pauldron_L.dds"
})
framework.effects.conjuration.createBasicBoundArmorEffect({
    id = tes3.effect.boundRightPauldron,
    name = "Призвать правый наплечник",
    description = getSingleDescription("Даэдрического правого наплечника"),
    baseCost = 2,
    armorId = "OJ_ME_BoundPauldronRight",
    icon = "RFD\\RFD_lf_pauldron_R.dds"
})
