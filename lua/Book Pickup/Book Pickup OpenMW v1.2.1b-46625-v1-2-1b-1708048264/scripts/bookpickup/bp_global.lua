local types = require("openmw.types")
local acti = require("openmw.interfaces").Activation
local core = require("openmw.core")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local shiftPressed = false
if (core.API_REVISION < 54) then
    error("Newer version of OpenMW is required")
end
I.Settings.registerGroup {
    key = "SettingsBookPickup",
    page = "BookPickup",
    l10n = "BookPickup",
    name = 'core.modName',
    description = 'mcm.credits',
    permanentStorage = true,
    settings = {
        {
            key = "PickupByDefault",
            renderer = "checkbox",
            name = "mcm.pickupByDefault.label",
            description =
            "mcm.pickupByDefault.description",
            default = "true"
        }, --This is the only possible setting at the moment, we can't allow stealing an item since moving it via lua would make it free.
    }
}

local function activateBook(object, actor)
    local defaultSetting = storage.globalSection("SettingsBookPickup"):get("PickupByDefault")
    if (object.owner.recordId ~= nil or object.owner.factionId ~= nil or object.cell == nil) then
        return --We should not automatically pick up owned books
    end
    if (shiftPressed and defaultSetting or shiftPressed == false and defaultSetting == false) then
        return --Will prevent if shift is pressed, or inverse if that setting is changed.
    end
    actor:sendEvent("playAmbientNoise", "book open")
    object:moveInto(actor)
    --Moves the book item into the player's inventory.
    return false
end
acti.addHandlerForType(types.Book, activateBook)
--Will trigger the above function whenever books are activated. Note that this will not work on books with scripts.
local function BookPickupShiftUpdate(val) shiftPressed = val end
--local function BookPickupUpdateSetting(bool) storage.globalSection("BookPickup"):set("pickupByDefault", bool) end
return {
    eventHandlers = {
        BookPickupShiftUpdate = BookPickupShiftUpdate,
  --      BookPickupUpdateSetting = BookPickupUpdateSetting,
    }
}
