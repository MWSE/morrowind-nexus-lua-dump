local I      = require("openmw.interfaces")
local shared = require("scripts.pickupanim_shared")

I.Settings.registerPage {
    key         = "PickupAnim",
    l10n        = "PickupAnim",
    name        = "page_name",
    description = "page_desc",
}

I.Settings.registerGroup {
    key              = "SettingsPickupAnim",
    page             = "PickupAnim",
    l10n             = "PickupAnim",
    name             = "settings_groupName",
    permanentStorage = true,
    order            = 1,
    settings = {
        {
            key         = "ENABLED_ITEMS",
            name        = "enabled_items_name",
            description = "enabled_items_desc",
            renderer    = "checkbox",
            default     = shared.DEFAULTS.ENABLED_ITEMS,
        },
        {
            key         = "ENABLED_DOORS",
            name        = "enabled_doors_name",
            description = "enabled_doors_desc",
            renderer    = "checkbox",
            default     = shared.DEFAULTS.ENABLED_DOORS,
        },
        {
            key         = "ENABLED_CONTAINERS",
            name        = "enabled_containers_name",
            description = "enabled_containers_desc",
            renderer    = "checkbox",
            default     = shared.DEFAULTS.ENABLED_CONTAINERS,
        },
        {
            key         = "DISABLE_CAMERA_SHAKE",
            name        = "disable_camera_shake_name",
            description = "disable_camera_shake_desc",
            renderer    = "checkbox",
            default     = shared.DEFAULTS.DISABLE_CAMERA_SHAKE,
        },
        {
            key         = "ITEM_SPEED",
            name        = "item_speed_name",
            description = "item_speed_desc",
            renderer    = "number",
            default     = shared.DEFAULTS.ITEM_SPEED,
            argument    = { min = 1.0, max = 2.5 },
        },
    },
}