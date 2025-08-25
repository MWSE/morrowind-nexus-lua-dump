local storage = require("openmw.storage")
local ambient = require("openmw.ambient")
local core = require("openmw.core")
local ui = require("openmw.ui")

local l10n = core.l10n("ModernMehrunesRazor")
local sectionOnInstakill = storage.playerSection("SettingsModernMehrunesRazor_onInstakill")

local function onLoad()
    -- always check your API version
    if core.API_REVISION < 87 then ui.showMessage(l10n("messageOutdatedLuaAPI"), { showInDualogue = true }) end
end

local function onInstakill()
    if sectionOnInstakill:get("showMessage") then ui.showMessage(l10n("messageDaedricBanishing")) end
    if sectionOnInstakill:get("playSFX") then ambient.playSound("critical damage") end
end

return {
    engineHandlers = {
        onLoad = onLoad
    },
    eventHandlers = {
        onInstakill = onInstakill
    }
}
