-- world/modRegistry.lua
-- Tiny pure-constant module safe for MENU/GLOBAL/PLAYER/NPC contexts.
-- Do not require runtime OpenMW gameplay APIs here.
local module = {}

module.MOD_ID = "SitDownPlease"
module.VERSION = "3.4"
module.DISPLAY_VERSION = "3.4"
module.SETTINGS_PAGE = "SitDownPlease"
module.SETTINGS_GROUP = "SettingsSitDownPlease" -- legacy storage section; still read for compatibility
module.SETTINGS_SITTING_GROUP = "SettingsSitDownPleaseSitting"
module.SETTINGS_SLEEPING_GROUP = "SettingsSitDownPleaseSleeping"
module.SETTINGS_LIGHTING_GROUP = "SettingsSitDownPleaseLighting"
module.SETTINGS_COMPATIBILITY_GROUP = "SettingsSitDownPleaseCompatibility"
module.SETTINGS_BLACKLIST_GROUP = "SettingsSitDownPleaseBlacklist"
module.SETTINGS_DIAGNOSTICS_GROUP = "SettingsSitDownPleaseDiagnostics"
module.SETTINGS_ADVANCED_GROUP = "SettingsSitDownPleaseAdvanced"
module.L10N = "SitDownPlease"

return module
