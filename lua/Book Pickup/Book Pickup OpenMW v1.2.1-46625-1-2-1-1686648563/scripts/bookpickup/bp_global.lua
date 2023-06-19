local types = require("openmw.types")
local world = require("openmw.world")
local acti = require("openmw.interfaces").Activation
local core = require("openmw.core")
local storage = require("openmw.storage")
local shiftPressed = false
if (core.API_REVISION < 37) then
    error("Newer version of OpenMW is required")
end
if (core.contentFiles ~= nil and not core.contentFiles.has("bookpickup.omwaddon")) then
    error("Book Pickup OmwAddon is not enabled!")
end
local function activateBook(object, actor)
    local defaultSetting = storage.globalSection("BookPickup"):get("pickupByDefault")
    if (object.ownerRecordId ~= nil or object.ownerFactionId ~= nil) then
        return--We should not automatically pick up owned books
    end
    if(shiftPressed and defaultSetting  or shiftPressed == false and defaultSetting == false) then
        return--Will prevent if shift is pressed, or inverse if that setting is changed.
    end
    world.createObject("book_pickup_soundob"):moveInto(types.Actor.inventory(actor))
    --can't play sound with lua, so we create an object that plays from the inventory, then remoes itself
    object:moveInto(types.Actor.inventory(actor))
    --Moves the book item into the player's inventory.
    return false
end
acti.addHandlerForType(types.Book, activateBook)
--Will trigger the above function whenever books are activated. Note that this will not work on books with scripts.
local function BookPickupShiftUpdate(val) shiftPressed = val end
local function BookPickupUpdateSetting(bool) storage.globalSection("BookPickup"):set("pickupByDefault",bool )end
return {
    eventHandlers = {
        BookPickupShiftUpdate = BookPickupShiftUpdate,
        BookPickupUpdateSetting = BookPickupUpdateSetting,
    }
}
