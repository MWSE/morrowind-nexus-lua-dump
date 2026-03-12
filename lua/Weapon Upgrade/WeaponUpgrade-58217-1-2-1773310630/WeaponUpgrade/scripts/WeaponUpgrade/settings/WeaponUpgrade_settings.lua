local storage = require('openmw.storage')
local I = require('openmw.interfaces')

I.Settings.registerPage({
    key = 'WeaponUpgrade',
    l10n = 'WeaponUpgrade',
    name = 'Weapon Upgrade',
    description = "Let's you upgrade the armor.\n\nTo edit the materials themselves, go to scripts/WeaponUpgrade and edit the MaterialsStatTable.csv.",
})