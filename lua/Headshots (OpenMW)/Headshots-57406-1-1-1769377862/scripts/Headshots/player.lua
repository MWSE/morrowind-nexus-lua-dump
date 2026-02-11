local storage = require("openmw.storage")
local ambient = require("openmw.ambient")
local core = require("openmw.core")
local ui = require("openmw.ui")
require("scripts.Headshots.headshotLogic")

local l10n = core.l10n("Headshots")
local sectionOnHeadshot = storage.playerSection("SettingsHeadshots_onHeadshot")

local function onLoad()
    -- always check your API version
    if core.API_REVISION < 95 then
        ui.showMessage(l10n("messageOutdatedLuaAPI"), { showInDualogue = true })
    end
end

local function onHeadshot(args)
    local damageMult, distance = table.unpack(args)
    if sectionOnHeadshot:get("playSFX") then ambient.playSound("critical damage") end
    if sectionOnHeadshot:get("showMessage") then
        if damageMult == math.huge then
            ui.showMessage(l10n("messageInstakill"))
        else
            ui.showMessage(
                l10n("messageSuccessfulHeadshot1") ..
                string.format("%.2f", distance) ..
                l10n("messageSuccessfulHeadshot2") ..
                string.format("%.2f", damageMult) ..
                l10n("messageSuccessfulHeadshot3"))
        end
    end
end

return {
    engineHandlers = {
        onLoad = onLoad
    },
    eventHandlers = {
        onHeadshot = onHeadshot
    }
}
