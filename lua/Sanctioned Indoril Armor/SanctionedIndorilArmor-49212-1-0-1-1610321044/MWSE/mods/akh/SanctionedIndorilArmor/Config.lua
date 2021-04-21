local modInfo = require('akh.SanctionedIndorilArmor.ModInfo')

return mwse.loadConfig(modInfo.modName, {
    requiredTempleRank = 6,
    requiredQuestCompletion = nil,
    inconspicuousRobes = true,
    cautiousMerchants = true,
    greetingCheckGlobal = "WearingOrdinatorUni",
    armorScript = "OrdinatorUniform",
    strings = {
        labelProhibitedToWear = "Prohibited to wear. Ordinators will not take kindly to me wearing this in public.",
        labelSanctionedToWear = "Sanctioned to wear. I earned my right to wear this sacred armor. I shall do this with respect and pride."
    }
})