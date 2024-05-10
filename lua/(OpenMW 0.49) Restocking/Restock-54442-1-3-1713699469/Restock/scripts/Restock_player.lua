local storage = require('openmw.storage')
local I = require("openmw.interfaces")
local common = {MOD_ID="Restocking"}

I.Settings.registerPage {
    key = "Restocking",
    l10n = "Restocking",
    name = 'Restocking',
    description = 'Restocks all the items a merchant would usually restock immediately over the course of 24 hours instead\nWith special treatment of ingredients'
}
