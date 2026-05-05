local types = require("openmw.types")
local world = require("openmw.world")
local acti = require("openmw.interfaces").Activation
local util = require("openmw.util")
local I = require("openmw.interfaces")
local async = require("openmw.async")
local core = require("openmw.core")
local calendar = require('openmw_aux.calendar')
local storage = require("openmw.storage")

local section = storage.globalSection("SettingsEnhancedInns")

local defaultValues = {
    goldPerNight = 10,
    goldPerWeek = 60,
    safeSleep = true,
    autoCloseDoor = true,
    returnRoomKey = true,
    returnReservationNote = true,
}

I.Settings.registerGroup {
    key = "SettingsEnhancedInns",
    page = "EnhancedInns",
    l10n = "EnhancedInns",
    name = 'Enhanced inns',
    description = '',
    permanentStorage = true,
    settings = {
        {
            key = "safeSleep",
            renderer = "checkbox",
            name = "Safe Sleep",
            description =
            "If enabled, you will be safe from Assassins and 6th House agents while sleeping in a rented bed with a locked door.",
            default = true
        },
        {
            key = "autoCloseDoor",
            renderer = "checkbox",
            name = "Automatically Close Inn Doors",
            description =
            "If enabled, Inn Doors will close and lock automatically after opened.",
            default = true
        },
        {
            key = "returnRoomKey",
            renderer = "checkbox",
            name = "Automatically return Room Key",
            description =
            "If enabled, Inn Room Keys will be removed when the reservation expires",
            default = true
        },
        {
            key = "returnReservationNote",
            renderer = "checkbox",
            name = "Automatically return Reservation Note",
            description =
            "If enabled, Reservation Note Keys will be removed when the reservation expires",
            default = true
        },
        {
            key = "goldPerNight",
            renderer = "number",
            name = "Daily Inn Rate",
            description =
            "Determines the daily fee for Inns",
            default = 10
        },
        {
            key = "goldPerWeek",
            renderer = "number",
            name = "Weekly Inn Rate",
            description =
            "Determines the weekly fee for Inns",
            default = 60
        },
    }
}
local function getSetting(key)
    local setting = section:get(key)

    if setting ~= nil then
        return setting
    end
if  defaultValues[key] then
return  defaultValues[key]
end

end

local function SettingsEnhancedInnsUpdate(data)

    local val = data.value
    local key = data.key
    section:set(key,val)
end
return {
    interfaceName = "ZS_InnOverhaul_Settings",
    interface = {
        getSetting = getSetting,
    },
    engineHandlers = {
    },
    eventHandlers = {
        SettingsEnhancedInnsUpdate = SettingsEnhancedInnsUpdate,
    }
}
