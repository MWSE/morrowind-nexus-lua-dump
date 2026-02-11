local storage = require('openmw.storage')
local I = require('openmw.interfaces')

I.Settings.registerPage({
    key = 'ArmorUpgrade',
    l10n = 'ArmorUpgrade',
    name = 'Armor Upgrade',
    description = "Let's you upgrade the armor.\n\nTo edit the materials themselves, go to scripts/ArmorUpgrade and edit the MaterialsStatTable.csv.",
})

