local storage = require("openmw.storage")

Toggles = storage.globalSection("SettingsCanonicalGear_toggles")
Debug = storage.globalSection("SettingsCanonicalGear_debug")

GearedNPCs = {
    wizardStaff = {},
    mouthStaff = {},
    kingsOath = {},
    dorisaDarvel = false,
}